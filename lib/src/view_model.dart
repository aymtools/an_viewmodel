import 'dart:collection';

import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/widgets.dart';

part 'view_model_core.dart';
part 'view_model_tools.dart';

/// ViewModel基类
abstract class ViewModel {
  bool _mCleared = false;
  final Set<Cancellable> _closeables = HashSet();

  /// 执行清理
  @protected
  void onCleared() {}

  /// 添加一个自动清理的cancellable
  void addCloseable(Cancellable closeable) {
    if (_mCleared) return;
    _closeables.add(closeable);
  }

  /// 开启ViewModel的创建 销毁日志 仅在非release下有效
  /// 默认为 true
  static bool printLifecycle = true;
}

extension ViewModelExt on ViewModel {
  /// 添加一个自动清理的回调
  void onDispose(void Function() onDispose) {
    Cancellable cancellable = Cancellable();
    cancellable.onCancel.then((_) => onDispose());
    addCloseable(cancellable);
  }

  /// 生成一个基于viewModel生命周期的cancellable
  Cancellable makeCloseable() {
    final closeable = Cancellable();
    addCloseable(closeable);
    return closeable;
  }
}

extension _ViewModelClean on ViewModel {
  // 执行清理
  void clear() {
    if (_mCleared) return;
    _mCleared = true;
    for (Cancellable c in _closeables) {
      c.cancel();
    }
    _closeables.clear();
    onCleared();
  }
}

/// ViewModel的Store
class ViewModelStore {
  final Map<Object, ViewModel> mMap = HashMap();

  /// 放入一个ViewModel 如果已经存在则上一个执行清理
  void put<T extends ViewModel>(T viewModel) {
    ViewModel? oldViewModel = mMap[T];
    mMap[T] = viewModel;
    if (oldViewModel != null) {
      oldViewModel.onCleared();
    }
  }

  /// 获取ViewModel
  T? get<T extends ViewModel>() {
    return mMap[T] as T?;
  }

  /// 获取ViewModel
  T? remove<T extends ViewModel>() {
    Object? oldViewModel = mMap.remove(T);
    if (oldViewModel is ViewModel) {
      oldViewModel.onCleared();
    }
    return oldViewModel as T;
  }

  /// 当前已存在的KEY
  Set<Object> keys() {
    return Set.of(mMap.keys);
  }

  ///Clears internal storage and notifies ViewModels that they are no longer used.
  void clear() {
    for (ViewModel vm in mMap.values) {
      vm.clear();
      _debugPrintViewModelCleared(vm);
    }
    mMap.clear();
  }
}

/// ViewModel创建器1
typedef ViewModelFactory<VM extends ViewModel> = VM Function();

/// ViewModel创建器2
typedef ViewModelFactory2<VM extends ViewModel> = VM Function(Lifecycle);

/// ViewModelProvider 的创建器
typedef ViewModelProviderProducer = ViewModelProvider Function(LifecycleOwner);

/// 用来管理如何创建ViewModel
class ViewModelProvider {
  final ViewModelStore _viewModelStore = ViewModelStore();
  final Lifecycle _lifecycle;
  final Map<Type, Function> _factoryMap = HashMap();

  ViewModelProvider(this._lifecycle) {
    _lifecycle.addLifecycleObserver(LifecycleObserver.eventDestroy(() {
      _viewModelStore.clear();
      _factoryMap.clear();
    }));
  }

  @protected
  ViewModelStore get viewModelStore => _viewModelStore;

  @protected
  Lifecycle get lifecycle => _lifecycle;

  /// 使用当前的Provider获取或创建一个 ViewModel
  /// [lifecycle] 调用时的lifecycle 不一定是寄存的
  VM getOrCreate<VM extends ViewModel>(Lifecycle lifecycle,
      {ViewModelFactory<VM>? factory, ViewModelFactory2<VM>? factory2}) {
    var vmCache = _viewModelStore.get<VM>();
    if (vmCache != null) return vmCache;
    VM? vm = ViewModelProvider.newInstanceViewModel(_lifecycle,
        factories: _factoryMap, factory: factory, factory2: factory2);
    if (vm != null) {
      _viewModelStore.put<VM>(vm);
      return vm;
    }
    throw 'cannot find $VM factory';
  }

  /// 添加一个创建器1
  void addFactory<VM extends ViewModel>(ViewModelFactory<VM> factory) =>
      _factoryMap[VM] = factory;

  /// 添加一个创建器2
  void addFactory2<VM extends ViewModel>(ViewModelFactory2<VM> factory) =>
      _factoryMap[VM] = factory;

  /// 添加 全局的 创建器1
  static void addDefFactory<VM extends ViewModel>(ViewModelFactory<VM> factory,
          {ViewModelProviderProducer? producer}) =>
      _ViewModelDefFactories._instance
          .addFactory<VM>(factory, producer: producer);

  /// 添加 全局的 创建器2
  static void addDefFactory2<VM extends ViewModel>(
          ViewModelFactory2<VM> factory,
          {ViewModelProviderProducer? producer}) =>
      _ViewModelDefFactories._instance
          .addFactory2<VM>(factory, producer: producer);

  static ViewModelProviderProducer? _viewModelProviderProducer;

  /// 设置默认的viewModels的提供者 的创建方式
  static set producerDefault(ViewModelProviderProducer value) {
    assert(_viewModelProviderProducer == null,
        'set producerDefault can only be called once.');
    _viewModelProviderProducer = value;
  }

  static ViewModelProviderProducer get _producerDef {
    return _viewModelProviderProducer ??
        (owner) => owner.getViewModelProvider();
  }

  /// viewModels的提供者 指定为基于路由 路由页面内唯一
  static ViewModelProviderProducer get producerByRoute =>
      (owner) => owner.getViewModelProviderByRoute();

  /// viewModels的提供者 基于App app内唯一
  static ViewModelProviderProducer get producerByApp =>
      (owner) => owner.getViewModelProviderByApp();

  /// 设置默认的viewModels的提供者 的创建方式
  @Deprecated('use set producerDefault')
  static void viewModelProviderProducer<LO extends LifecycleOwnerStateMixin>(
          {bool Function(LO)? testLifecycleOwner}) =>
      producerDefault = (owner) => owner.findViewModelProvider<LO>(
          testLifecycleOwner: testLifecycleOwner);

  /// 设置默认的viewModels的提供者 指定为基于路由 路由页面内唯一
  @Deprecated('use set producerDefault')
  static void viewModelProviderProducerByRoute() =>
      producerDefault = ViewModelProvider.producerByRoute;

  /// 设置默认的viewModels的提供者 基于App app内唯一
  @Deprecated('use set producerDefault')
  static void viewModelProviderProducerByApp() =>
      producerDefault = ViewModelProvider.producerByApp;

  /// 使用提供的创建工厂来创建VM 对象
  /// [lifecycle] viewModel 所寄存的lifecycle
  static VM? newInstanceViewModel<VM extends ViewModel>(Lifecycle lifecycle,
      {Map<Type, Function>? factories,
      ViewModelFactory<VM>? factory,
      ViewModelFactory2<VM>? factory2}) {
    VM? result;
    result = factory?.call();
    result ??= factory2?.call(lifecycle);
    _debugPrintViewModelCreated(result, lifecycle, factory, factory2);
    if (result == null && factories != null) {
      result = _newInstanceViewModel<VM>(factories, lifecycle);
    }
    result ??= _newInstanceViewModel<VM>(
        _ViewModelDefFactories._instance._factoryMap, lifecycle);
    return result;
  }
}

VM? _newInstanceViewModel<VM extends ViewModel>(
    Map<Type, Function> factories, Lifecycle lifecycle) {
  VM? vm;
  Function? factory = factories[VM];
  if (factory is ViewModelFactory<VM>) {
    vm = factory();
    _debugPrintViewModelCreated(vm, lifecycle, factory, null);
  } else if (factory is ViewModelFactory2<VM>) {
    vm = factory(lifecycle);
    _debugPrintViewModelCreated(vm, lifecycle, null, factory);
  }
  return vm;
}

void _debugPrintViewModelCreated(ViewModel? vm, Lifecycle lifecycle,
    ViewModelFactory? factory, ViewModelFactory2? factory2) {
  assert(() {
    if (ViewModel.printLifecycle && vm != null) {
      debugPrint('ViewModel: ${vm.runtimeType}:${vm.hashCode} Created '
          'By ${lifecycle.owner.runtimeType}${lifecycle.owner.scope ?? ''}:${lifecycle.owner.hashCode}'
          // 'use factory ${factory ?? factory2 ?? ''}'
          '');
    }
    return true;
  }());
}

void _debugPrintViewModelCleared(ViewModel vm) {
  assert(() {
    if (ViewModel.printLifecycle) {
      debugPrint('ViewModel: ${vm.runtimeType}:${vm.hashCode} Cleared');
    }
    return true;
  }());
}
