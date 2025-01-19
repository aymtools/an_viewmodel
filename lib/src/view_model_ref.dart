import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/widgets.dart';

import 'view_model.dart';

/// 对缓存式的ViewModel提供支持
class RefViewModelProvider extends ViewModelProvider with ViewModel {
  final Map<Type, CancellableEvery> _cancellableMap = {};

  RefViewModelProvider(super.appLifecycle);

  @override
  ViewModelStore get viewModelStore => super.viewModelStore;

  @protected
  @override
  void onCleared() {
    super.onCleared();
    _cancellableMap.clear();
  }

  @override
  VM get<VM extends ViewModel>(
      {ViewModelFactory<VM>? factory, ViewModelFactory2<VM>? factory2}) {
    throw 'not implement use [getOrCreate]';
  }

  /// 获取 如果不存在则创建
  VM getOrCreate<VM extends ViewModel>(Lifecycle lifecycle,
      {ViewModelFactory<VM>? factory, ViewModelFactory2<VM>? factory2}) {
    final vm = super.get<VM>(factory: factory, factory2: factory2);

    final disposable = _cancellableMap.putIfAbsent(
        VM,
        () => CancellableEvery()
          ..onCancel.then((value) => viewModelStore.remove<VM>()));

    disposable.add(lifecycle.makeViewModelCancellable(vm));
    return vm;
  }
}

// class _ViewModelCancellableKey extends TypedKey<Cancellable> {
//   _ViewModelCancellableKey(Type super.key);
//
//   @override
//   int get hashCode => Object.hash(_ViewModelCancellableKey, key);
//
//   @override
//   bool operator ==(Object other) {
//     return other is _ViewModelCancellableKey && key == other.key;
//   }
// }

extension _LifecycleRefViewModelProviderVMCancellableExt on Lifecycle {
  Cancellable makeViewModelCancellable(ViewModel vm) =>
      extData.putIfAbsent(key: vm, ifAbsent: () => makeLiveCancellable());
}

extension ViewModelByRefExt on ILifecycle {
  /// 当还有引用时 下次获取依然是同一个 当没有任何引用的时候 会执行清理vm
  /// - factory2 创建的时候使用app lifecycle
  /// 对于回收不建议使用lifecycle参数 推荐使用VM的 [onCleared] [addCloseable] [onDispose]
  VM viewModelsByRef<VM extends ViewModel>(
      {ViewModelFactory<VM>? factory, ViewModelFactory2<VM>? factory2}) {
    return getRefViewModelProvider()
        .getOrCreate(toLifecycle(), factory: factory, factory2: factory2);
  }

  /// 获取 RefViewModelProvider
  RefViewModelProvider getRefViewModelProvider() =>
      viewModelsByApp<RefViewModelProvider>(factory2: RefViewModelProvider.new);
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
