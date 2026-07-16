import 'dart:collection';

import 'package:anlifecycle/anlifecycle.dart';
import 'package:flutter/widgets.dart';
import 'package:weak_collections/weak_collections.dart';

import 'view_model.dart';

class _ViewModelRefProviderManagerLifecycleObserver
    extends LifecycleEventObserver {
  bool _isDestroyed = false;
  final WeakLinkedHashSet<Lifecycle> _users = WeakLinkedHashSet.identity();
  final void Function(ViewModel?) onDispose;
  final WeakReference<ViewModel> _vmRef;

  _ViewModelRefProviderManagerLifecycleObserver(
      {required ViewModel vm, required this.onDispose})
      : _vmRef = WeakReference(vm);

  void add(Lifecycle lifecycle) {
    if (_isDestroyed) return;
    if (lifecycle.currentLifecycleState > LifecycleState.destroyed) {
      /// 将最后一次使用的生命周期 更新为最后一个
      if (_users.isEmpty) {
        /// 空的情况直接新增即可
        lifecycle.addLifecycleObserver(this);
      } else if (_users.last == lifecycle) {
        // 如果是最后一个则无需任何操作
        return;
      } else if (_users.contains(lifecycle)) {
        _users.remove(lifecycle);
      } else {
        lifecycle.addLifecycleObserver(this);
      }
      _users.add(lifecycle);
      return;
    }
    if (_users.isEmpty) {
      _isDestroyed = true;
      onDispose(_vmRef.target);
    }
  }

  void _check(Lifecycle willRemove) {
    _users.remove(willRemove);
    if (_users.isEmpty) {
      _isDestroyed = true;
      onDispose(_vmRef.target);
    }
  }

  @override
  void onDestroy(LifecycleOwner owner) {
    super.onDestroy(owner);
    _check(owner.lifecycle);
  }

  // 用来提供给viewModel的获取hostLifecycle
  Lifecycle _hostLifecycle() => _users.last;
}

/// 对缓存式的ViewModel提供支持
class RefViewModelProvider extends ViewModelProvider {
  final Map<ViewModel, _ViewModelRefProviderManagerLifecycleObserver>
      _cancellableMap = HashMap.identity();

  RefViewModelProvider(Lifecycle lifecycle) : super(lifecycle) {
    lifecycle.addLifecycleObserver(
        LifecycleObserver.eventDestroy(_cancellableMap.clear));
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
    final _ViewModelRefProviderManagerLifecycleObserver manager =
        _cancellableMap.putIfAbsent(vm, () {
      final manager = _ViewModelRefProviderManagerLifecycleObserver(
        vm: vm,
        onDispose: (vm) {
          if (vm != null) {
            resetViewModelHostLifecycle(vm);
            _cancellableMap.remove(vm);
          }
          viewModelStore.remove<VM>(vmType: vmType);
        },
      );
      changeViewModelHostLifecycle(vm, manager._hostLifecycle);
      return manager;
    });
    manager.add(lifecycle);
    return vm;
  }
}

extension ViewModelProviderProducerConfigRefExt
    on ViewModelProviderProducerCompanion {
  /// 缓存式的ViewModel提供支持的提供者
  /// - 必须要有一个顶级的lifecycleOwner 一般是app
  /// - 如果存在多个顶 怎会产生多个 RefViewModelProvider viewModels的结果会根据不同的provider返回
  ViewModelProviderProducer get byRef =>
      (owner) => owner.getRefViewModelProvider();
}

final Map<LifecycleOwner, RefViewModelProvider> _refViewModelProviderMap =
    WeakHashMap.identity();

extension ViewModelByRefExt on ILifecycle {
  /// 当还有引用时 下次获取依然是同一个 当没有任何引用的时候 会执行清理vm
  /// - [factory2] 创建的时候使用最顶层的[lifecycle]
  /// - 对于回收不建议使用[lifecycle]参数 推荐使用VM的 [onCleared], [addCloseable], [onDispose]
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
  /// - [factory2] 创建的时候使用最顶层的[lifecycle]
  /// - 对于回收不建议使用[lifecycle]参数 推荐使用VM的 [onCleared], [addCloseable], [onDispose]
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
  /// - [factory2] 创建的时候使用最顶层的[lifecycle]
  /// - 对于回收不建议使用[lifecycle]参数 推荐使用VM的 [onCleared]，[addCloseable], [onDispose]
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
