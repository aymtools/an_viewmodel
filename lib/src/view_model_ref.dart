import 'dart:collection';

import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/widgets.dart';

import 'view_model.dart';

/// 对缓存式的ViewModel提供支持
class RefViewModelProvider extends ViewModelProvider {
  final Map<ViewModel, CancellableEvery> _cancellableMap = HashMap();

  RefViewModelProvider(super.appLifecycle) {
    lifecycle
        .makeLiveCancellable()
        .onCancel
        .then((_) => _cancellableMap.clear());
  }

  @override
  ViewModelStore get viewModelStore => super.viewModelStore;

  /// 获取 如果不存在则创建
  @override
  VM getOrCreate<VM extends ViewModel>(Lifecycle lifecycle,
      {ViewModelFactory<VM>? factory, ViewModelFactory2<VM>? factory2}) {
    final vm =
        super.getOrCreate<VM>(lifecycle, factory: factory, factory2: factory2);

    final disposable = _cancellableMap.putIfAbsent(
        vm,
        () => CancellableEvery()
          ..onCancel.then((value) => viewModelStore.remove<VM>()));

    disposable.add(lifecycle.makeViewModelCancellable(vm));
    return vm;
  }
}

final _keyRefViewModelProviderVMCancellable = Object();

extension _LifecycleRefViewModelProviderVMCancellableExt on Lifecycle {
  Cancellable makeViewModelCancellable(ViewModel vm) => extData.putIfAbsent(
      key: _keyRefViewModelProviderVMCancellable,
      ifAbsent: () => makeLiveCancellable());
}

extension ViewModelProviderProducerConfigRefExt
    on ViewModelProviderProducerCompanion {
  /// 缓存式的ViewModel提供支持的提供者
  ViewModelProviderProducer get byRef =>
      (owner) => owner.getRefViewModelProvider();
}

final _keyRefViewModelProvider = Object();

extension ViewModelByRefExt on ILifecycle {
  /// 当还有引用时 下次获取依然是同一个 当没有任何引用的时候 会执行清理vm
  /// - factory2 创建的时候使用app lifecycle
  /// 对于回收不建议使用lifecycle参数 推荐使用VM的 [onCleared] [addCloseable] [onDispose]
  VM viewModelsByRef<VM extends ViewModel>(
      {ViewModelFactory<VM>? factory, ViewModelFactory2<VM>? factory2}) {
    // toLifecycle().
    return viewModels(
        factory: factory,
        factory2: factory2,
        viewModelProviderProducer: ViewModel.producer.byRef);
  }

  /// 获取 RefViewModelProvider
  RefViewModelProvider getRefViewModelProvider() {
    final appLifecycle = findLifecycleOwner<LifecycleOwnerState>(
        test: (owner) => owner.lifecycle.parent == null)!;
    return appLifecycle.extData.getOrPut(
        key: _keyRefViewModelProvider, ifAbsent: RefViewModelProvider.new);
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
    return context.viewModelsByRef(factory: factory, factory2: factory2);
  }
}
