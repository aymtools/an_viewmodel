import 'dart:collection';

import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/widgets.dart';

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
  void clear() {
    if (_mCleared) return;
    _mCleared = true;
    for (Cancellable c in _closeables) {
      c.cancel();
    }
    _closeables.clear();
    onCleared();
    _debugPrintViewModelCleared(this);
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
      oldViewModel.clear();
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
      oldViewModel.clear();
    }
    return oldViewModel as T;
  }

  /// 当前已存在的KEY
  Set<Object> keys() {
    return Set.of(mMap.keys);
  }

  ///Clears internal storage and notifies ViewModels that they are no longer used.
  void clear() {
    if (mMap.isNotEmpty) {
      for (ViewModel vm in [...mMap.values]) {
        vm.clear();
      }
    }
    mMap.clear();
  }
}

/// ViewModel创建器1
typedef ViewModelFactory<VM extends ViewModel> = VM Function();

/// ViewModel创建器2
typedef ViewModelFactory2<VM extends ViewModel> = VM Function(Lifecycle);

class _ViewModelDefFactories {
  static final _ViewModelDefFactories _instance = _ViewModelDefFactories();

  final Map<Type, Function> _factoryMap = HashMap();

  void addFactory<VM extends ViewModel>(ViewModelFactory<VM> factory) =>
      _factoryMap[VM] = factory;

  void addFactory2<VM extends ViewModel>(ViewModelFactory2<VM> factory) =>
      _factoryMap[VM] = factory;
}

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
  VM get<VM extends ViewModel>(
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
  static void addDefFactory<VM extends ViewModel>(
          ViewModelFactory<VM> factory) =>
      _ViewModelDefFactories._instance.addFactory<VM>(factory);

  /// 添加 全局的 创建器2
  static void addDefFactory2<VM extends ViewModel>(
          ViewModelFactory2<VM> factory) =>
      _ViewModelDefFactories._instance.addFactory2<VM>(factory);

  static ViewModelProviderProducer? _viewModelProviderProducer;

  /// 设置默认的viewModels的提供者 的创建方式
  static set producerDefault(ViewModelProviderProducer value) {
    assert(_viewModelProviderProducer == null,
        'set producerDefault can only be called once.');
    _viewModelProviderProducer = value;
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

extension ViewModelProviderViewModelsExt on ViewModelProvider {
  /// 扩展的get 可提供临时的 ViewModelFactory
  VM viewModels<VM extends ViewModel>(
      {ViewModelFactory<VM>? factory, ViewModelFactory2<VM>? factory2}) {
    // if (factory != null) {
    //   addFactory(factory);
    // }
    // if (factory2 != null) {
    //   addFactory2(factory2);
    // }
    return get<VM>(factory: factory, factory2: factory2);
  }
}

final _keyViewModelProvider = Object();

extension ViewModelStoreOwnerExtension on LifecycleOwner {
  /// 获取 当前的viewModelStore
  ViewModelStore getViewModelStore() => getViewModelProvider().viewModelStore;

  /// 获取当前的 viewModelProvider
  ViewModelProvider getViewModelProvider() {
    assert(currentLifecycleState > LifecycleState.destroyed,
        'Must be used before destroyed.');
    return extData.putIfAbsent<ViewModelProvider>(
        key: _keyViewModelProvider,
        ifAbsent: () => ViewModelProvider(lifecycle));
  }

  /// 查找最近的路由page 级别的 viewModelProvider
  ViewModelProvider getViewModelProviderByRoute() =>
      findViewModelProvider<LifecycleRouteOwnerState>();

  /// 查找最近的App 级别的 viewModelProvider
  ViewModelProvider getViewModelProviderByApp() =>
      findViewModelProvider<LifecycleAppOwnerState>(
          testLifecycleOwner: (owner) => owner.lifecycle.parent == null);

  /// 自定义查找模式 的 viewModelProvider
  ViewModelProvider findViewModelProvider<LO extends LifecycleOwnerStateMixin>(
          {bool Function(LO)? testLifecycleOwner}) =>
      _getViewModelProvider<LO>(testLifecycleOwner: testLifecycleOwner);
}

extension _ViewModelRegistryExtension on ILifecycleRegistry {
  ViewModelProvider _getViewModelProvider<LO extends LifecycleOwnerStateMixin>(
      {bool Function(LO)? testLifecycleOwner}) {
    final owner = _findLifecycleOwner<LO>(test: testLifecycleOwner);
    if (owner == null) {
      throw 'cannot find $LO';
    }
    return owner.getViewModelProvider();
  }

  LO? _findLifecycleOwner<LO extends LifecycleOwnerStateMixin>(
      {bool Function(LO)? test}) {
    Lifecycle? life = lifecycle;
    if (test == null) {
      while (life != null) {
        if (life.owner is LO) {
          return (life.owner as LO);
        }
        life = life.parent;
      }
      return null;
    }
    while (life != null) {
      if (life.owner is LO && test((life.owner as LO))) {
        return (life.owner as LO);
      }
      life = life.parent;
    }
    return null;
  }
}

extension ViewModelLifecycleExtension on ILifecycle {
  /// 获取当前环境下配置下的ViewModel
  VM viewModels<VM extends ViewModel>({
    ViewModelFactory<VM>? factory,
    ViewModelFactory2<VM>? factory2,
    @Deprecated('use viewModelProviderProducer')
    ViewModelProvider Function(LifecycleOwner lifecycleOwner)?
        viewModelProvider,
    ViewModelProvider Function(LifecycleOwner lifecycleOwner)?
        viewModelProviderProducer,
  }) {
    final ILifecycleRegistry registry = toLifecycleRegistry();
    final owner = registry._findLifecycleOwner();
    if (owner == null) {
      throw 'cannot find LifecycleOwner';
    }
    // 兼容一段时间未来移除
    viewModelProviderProducer ??= viewModelProvider;

    viewModelProviderProducer ??= ViewModelProvider._viewModelProviderProducer;
    viewModelProviderProducer ??= (owner) => owner.getViewModelProvider();

    return viewModelProviderProducer
        .call(owner)
        .viewModels(factory: factory, factory2: factory2);
  }

  /// 获取基于RoutePage的ViewModel
  VM viewModelsByRoute<VM extends ViewModel>({
    ViewModelFactory<VM>? factory,
    ViewModelFactory2<VM>? factory2,
  }) =>
      viewModels(
          factory: factory,
          factory2: factory2,
          viewModelProviderProducer: ViewModelProvider.producerByRoute);

  /// 获取基于App的ViewModel
  VM viewModelsByApp<VM extends ViewModel>({
    ViewModelFactory<VM>? factory,
    ViewModelFactory2<VM>? factory2,
  }) =>
      viewModels(
          factory: factory,
          factory2: factory2,
          viewModelProviderProducer: ViewModelProvider.producerByApp);

  /// 自定义按需查找的 ViewModel
  VM viewModelsByLifecycleOwner<VM extends ViewModel,
              LO extends LifecycleOwnerStateMixin>(
          {ViewModelFactory<VM>? factory,
          ViewModelFactory2<VM>? factory2,
          bool Function(LO)? testLifecycleOwner}) =>
      viewModels(
          factory: factory,
          factory2: factory2,
          viewModelProviderProducer: (owner) => owner.findViewModelProvider<LO>(
              testLifecycleOwner: testLifecycleOwner));
}

extension ViewModelsOfBuildContextExt on BuildContext {
  /// 获取最近的指定的 viewModelProvider 可提供的 ViewModel
  VM viewModels<VM extends ViewModel>({
    ViewModelFactory<VM>? factory,
    ViewModelFactory2<VM>? factory2,
    @Deprecated('use viewModelProviderProducer')
    ViewModelProvider Function(LifecycleOwner lifecycleOwner)?
        viewModelProvider,
    ViewModelProvider Function(LifecycleOwner lifecycleOwner)?
        viewModelProviderProducer,
  }) {
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
    return lifecycle!.viewModels(
        factory: factory,
        factory2: factory2,
        viewModelProviderProducer:
            viewModelProviderProducer ?? viewModelProvider);
  }

  /// 获取最近的Route提供的 viewModelProvider 来获取 ViewModel
  VM viewModelsByRoute<VM extends ViewModel>(
          {ViewModelFactory<VM>? factory, ViewModelFactory2<VM>? factory2}) =>
      viewModels(
          factory: factory,
          factory2: factory2,
          viewModelProviderProducer: ViewModelProvider.producerByRoute);

  /// 获取基于App的ViewModel
  VM viewModelsByApp<VM extends ViewModel>(
          {ViewModelFactory<VM>? factory, ViewModelFactory2<VM>? factory2}) =>
      viewModels(
          factory: factory,
          factory2: factory2,
          viewModelProviderProducer: ViewModelProvider.producerByApp);
}

extension ViewModelsState<T extends StatefulWidget> on State<T> {
  /// 获取最近的指定的 viewModelProvider 可提供的 ViewModel
  VM viewModelsOfState<VM extends ViewModel>({
    ViewModelFactory<VM>? factory,
    ViewModelFactory2<VM>? factory2,
    @Deprecated('use viewModelProviderProducer')
    ViewModelProvider Function(LifecycleOwner lifecycleOwner)?
        viewModelProvider,
    ViewModelProvider Function(LifecycleOwner lifecycleOwner)?
        viewModelProviderProducer,
  }) {
    if (this is ILifecycleRegistry) {
      return (this as ILifecycleRegistry).viewModels(
          factory: factory,
          factory2: factory2,
          viewModelProviderProducer:
              viewModelProviderProducer ?? viewModelProvider);
    }
    assert(mounted);

    return context.viewModels(
        factory: factory,
        factory2: factory2,
        viewModelProviderProducer:
            viewModelProviderProducer ?? viewModelProvider);
  }

  /// 获取最近的Route提供的 viewModelProvider 来获取 ViewModel
  VM viewModelsByRouteOfState<VM extends ViewModel>(
          {ViewModelFactory<VM>? factory, ViewModelFactory2<VM>? factory2}) =>
      viewModelsOfState(
          factory: factory,
          factory2: factory2,
          viewModelProviderProducer: ViewModelProvider.producerByRoute);

  /// 获取基于App的ViewModel
  VM viewModelsByAppOfState<VM extends ViewModel>(
          {ViewModelFactory<VM>? factory, ViewModelFactory2<VM>? factory2}) =>
      viewModelsOfState(
          factory: factory,
          factory2: factory2,
          viewModelProviderProducer: ViewModelProvider.producerByApp);
}
