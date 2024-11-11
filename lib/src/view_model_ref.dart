import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/widgets.dart';

import 'view_model.dart';

/// 对缓存式的ViewModel提供支持
class RefViewModelProvider with ViewModel implements ViewModelProvider {
  final ViewModelStore _viewModelStore;
  final Map<Type, Function> _factoryMap = {};
  final Map<String, CancellableEvery> _cancellableMap = {};

  RefViewModelProvider() : _viewModelStore = ViewModelStore();

  @override
  void onCleared() {
    super.onCleared();
    _cancellableMap.clear();
    _viewModelStore.clear();
    _factoryMap.clear();
  }

  @override
  void addFactory<VM extends ViewModel>(ViewModelFactory<VM> factory) {
    _factoryMap[VM] = factory;
  }

  @override
  void addFactory2<VM extends ViewModel>(ViewModelFactory2<VM> factory) {
    _factoryMap[VM] = factory;
  }

  @override
  VM get<VM extends ViewModel>() {
    throw 'not implement use [getOrCreate]';
  }

  /// 获取 如果不存在则创建
  VM getOrCreate<VM extends ViewModel>(Lifecycle lifecycle,
      {ViewModelFactory<VM>? factory, ViewModelFactory2<VM>? factory2}) {
    final vmKey = VM.toString();

    var vmCached = _viewModelStore.get(vmKey);
    if (vmCached != null) {
      assert(vmCached is VM,
          'cached ViewModel(${vmCached.runtimeType}) is not $VM');

      final cancellable = _cancellableMap[vmKey];
      cancellable?.add(lifecycle.makeViewModelCancellable(vmKey));

      return vmCached as VM;
    }

    if (!_factoryMap.containsKey(VM)) {
      if (factory != null) {
        _factoryMap[VM] = factory;
      } else if (factory2 != null) {
        _factoryMap[VM] = factory2;
      }
    }
    VM? vm = ViewModelProvider.newInstanceViewModel(lifecycle,
        factories: _factoryMap);
    if (vm != null) {
      _viewModelStore.put(vmKey, vm);
      final cancellable = CancellableEvery();
      cancellable.onCancel.then((value) => _viewModelStore.remove(vmKey));
      _cancellableMap[vmKey] = cancellable;
      cancellable.add(lifecycle.makeViewModelCancellable(vmKey));
      return vm;
    }
    throw 'cannot find $VM factory';
  }
}

const Object _key = Object();

class PairKey {
  final Object first;
  final Object last;

  PairKey(this.first, this.last);

  @override
  int get hashCode => Object.hash(first, first);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PairKey && other.first == first && other.last == last;
  }
}

extension _LifecycleRefViewModelProviderVMCancellableExt on Lifecycle {
  Cancellable makeViewModelCancellable(String key) =>
      lifecycleExtData.putIfAbsent(TypedKey<Cancellable>(PairKey(_key, key)),
          () => makeLiveCancellable());
}

extension ViewModelByRefExt on ILifecycle {
  /// 当还有引用时 下次获取依然是同一个 当没有任何引用的时候 会执行清理vm
  /// - factory2 回传的lifecycle是 首次创建的时候使用lifecycle 会存在lifecycle销毁但是vm依然需要生存的状态
  /// 对于回收不建议使用lifecycle参数 推荐使用VM的 [onCleared] [addCloseable] [onDispose]
  VM viewModelsByRef<VM extends ViewModel>(
      {ViewModelFactory<VM>? factory, ViewModelFactory2<VM>? factory2}) {
    final vmx = viewModelsByApp<RefViewModelProvider>(
        factory: RefViewModelProvider.new);
    return vmx.getOrCreate(toLifecycle(), factory: factory, factory2: factory2);
  }
}

extension ViewModelsByRefOfBuildContextExt on BuildContext {
  /// 当还有引用时 下次获取依然是同一个 当没有任何引用的时候 会执行清理vm
  /// - factory2 回传的lifecycle是 首次创建的时候使用lifecycle 会存在lifecycle销毁但是vm依然需要生存的状态
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
  /// - factory2 回传的lifecycle是 首次创建的时候使用lifecycle 会存在lifecycle销毁但是vm依然需要生存的状态
  /// 对于回收不建议使用lifecycle参数 推荐使用VM的 [onCleared] [addCloseable] [onDispose]
  VM viewModelsByRefOfState<VM extends ViewModel>(
      {ViewModelFactory<VM>? factory, ViewModelFactory2<VM>? factory2}) {
    if (this is ILifecycleRegistry) {
      return (this as ILifecycleRegistry)
          .viewModelsByRef(factory: factory, factory2: factory2);
    }
    assert(mounted);
    return context.viewModelsByRef(factory: factory, factory2: factory2);
  }
}
