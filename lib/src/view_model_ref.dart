import 'dart:collection';

import 'package:anlifecycle/anlifecycle.dart';
import 'package:flutter/widgets.dart';
import 'package:weak_collections/weak_collections.dart';

import 'view_model.dart';

class _RefManager extends LifecycleEventObserver {
  bool _isDestroyed = false;
  final Set<Lifecycle> _users = WeakHashSet();
  final void Function() onDispose;

  _RefManager({required this.onDispose});

  void add(Lifecycle lifecycle) {
    if (_isDestroyed) return;
    if (lifecycle.currentLifecycleState > LifecycleState.destroyed) {
      if (_users.add(lifecycle)) {
        lifecycle.addLifecycleObserver(this);
      }
      return;
    }
    if (_users.isEmpty) {
      _isDestroyed = true;
      onDispose();
    }
  }

  _check(Lifecycle willRemove) {
    _users.remove(willRemove);
    if (_users.isEmpty) {
      _isDestroyed = true;
      onDispose();
    }
  }

  @override
  void onDestroy(LifecycleOwner owner) {
    super.onDestroy(owner);
    _check(owner.lifecycle);
  }
}

/// 对缓存式的ViewModel提供支持
class RefViewModelProvider extends ViewModelProvider {
  final Map<ViewModel, _RefManager> _cancellableMap = HashMap.identity();

  RefViewModelProvider(Lifecycle lifecycle) : super(lifecycle) {
    lifecycle.addLifecycleObserver(
        LifecycleObserver.eventCreate(_cancellableMap.clear));
  }

  @override
  ViewModelStore get viewModelStore => super.viewModelStore;

  /// 获取 如果不存在则创建
  @override
  VM getOrCreateViewModel<VM extends ViewModel>(Lifecycle lifecycle,
      {ViewModelFactory<VM>? factory,
      ViewModelFactory2<VM>? factory2,
      Type? vmType}) {
    final vm = super.getOrCreateViewModel<VM>(lifecycle,
        factory: factory, factory2: factory2, vmType: vmType);
    final _RefManager manager = _cancellableMap.putIfAbsent(
        vm,
        () => _RefManager(onDispose: () {
              viewModelStore.remove<VM>();
              _cancellableMap.remove(vm);
            }));
    manager.add(lifecycle);
    return vm;
  }
}

extension ViewModelProviderProducerConfigRefExt
    on ViewModelProviderProducerCompanion {
  /// 缓存式的ViewModel提供支持的提供者
  ViewModelProviderProducer get byRef =>
      (owner) => owner.getRefViewModelProvider();
}

final Map<LifecycleOwner, RefViewModelProvider> _refViewModelProviderMap =
    WeakHashMap();

extension ViewModelByRefExt on ILifecycle {
  /// 当还有引用时 下次获取依然是同一个 当没有任何引用的时候 会执行清理vm
  /// - factory2 创建的时候使用app lifecycle
  /// 对于回收不建议使用lifecycle参数 推荐使用VM的 [onCleared] [addCloseable] [onDispose]
  VM viewModelsByRef<VM extends ViewModel>(
      {ViewModelFactory<VM>? factory, ViewModelFactory2<VM>? factory2}) {
    // toLifecycle().
    return viewModels<VM>(
        factory: factory,
        factory2: factory2,
        viewModelProviderProducer: ViewModel.producer.byRef);
  }

  /// 获取 RefViewModelProvider
  RefViewModelProvider getRefViewModelProvider() {
    final appLifecycle = _findTopLifecycleOwner();
    assert(appLifecycle.currentLifecycleState > LifecycleState.destroyed);
    return _refViewModelProviderMap.putIfAbsent(appLifecycle, () {
      final result = RefViewModelProvider(appLifecycle.lifecycle);
      if (appLifecycle.currentLifecycleState > LifecycleState.destroyed) {
        appLifecycle.addLifecycleObserver(
            LifecycleObserver.onEventDestroy(_refViewModelProviderMap.remove));
      }
      return result;
    });
  }

  LifecycleOwner _findTopLifecycleOwner() {
    Lifecycle lifecycle = toLifecycle();
    while (lifecycle.parent != null) {
      lifecycle = lifecycle.parent!;
    }
    return lifecycle.owner;
  }
}

extension ViewModelsByRefOfBuildContextExt on BuildContext {
  /// 当还有引用时 下次获取依然是同一个 当没有任何引用的时候 会执行清理vm
  /// - factory2 创建的时候使用app lifecycle
  /// 对于回收不建议使用lifecycle参数 推荐使用VM的 [onCleared] [addCloseable] [onDispose]
  VM viewModelsByRef<VM extends ViewModel>(
      {ViewModelFactory<VM>? factory, ViewModelFactory2<VM>? factory2}) {
    Lifecycle? lifecycle;
    assert(() {
      /// 抑制掉 assert 时的异常
      try {
        lifecycle = Lifecycle.of(this);
      } catch (_) {
        lifecycle = Lifecycle.of(this, listen: false);
      }
      return true;
    }());
    lifecycle ??= Lifecycle.of(this);

    return lifecycle!.viewModelsByRef<VM>(factory: factory, factory2: factory2);
  }
}

extension ViewModelsByRefOfStateExt<W extends StatefulWidget> on State<W> {
  /// 当还有引用时 下次获取依然是同一个 当没有任何引用的时候 会执行清理vm
  /// - factory2 创建的时候使用app lifecycle
  /// 对于回收不建议使用lifecycle参数 推荐使用VM的 [onCleared] [addCloseable] [onDispose]
  VM viewModelsByRefOfState<VM extends ViewModel>(
      {ViewModelFactory<VM>? factory, ViewModelFactory2<VM>? factory2}) {
    if (this is ILifecycleRegistry) {
      return (this as ILifecycleRegistry)
          .viewModelsByRef(factory: factory, factory2: factory2);
    }
    assert(mounted);
    return context.viewModelsByRef<VM>(factory: factory, factory2: factory2);
  }
}
