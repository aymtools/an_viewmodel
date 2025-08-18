import 'dart:collection';

import 'package:anlifecycle/anlifecycle.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/widgets.dart';
import 'package:weak_collections/weak_collections.dart';

part 'view_model_companion.dart';
part 'view_model_core.dart';
part 'view_model_tools.dart';

/// ViewModel基类
abstract mixin class ViewModel {
  // bool _mCleared = false;
  final Cancellable _cancellable = Cancellable();
  late WeakReference<Lifecycle> _lifecycle;

  /// 调用完构造函数之后调用 初始化创建
  /// [lifecycle] 当前ViewModel所寄存的 lifecycle
  @protected
  void onCreate(Lifecycle lifecycle) {}

  /// 执行清理
  @protected
  void onCleared() {}

  /// 添加一个自动清理的cancellable
  @Deprecated('use makeLiveCancellable')
  void addCloseable(Cancellable closeable) {
    if (_cancellable.isUnavailable) return;
    _cancellable.onCancel.then(closeable.cancel);
  }

  /// 开启ViewModel的创建 销毁日志 仅在非release下有效
  /// 默认为 true
  static bool printLifecycle = true;

  /// 不要每次使用 assert 去检查 ProviderProducer 的合法性 自动使用第一次注册的 默认值为false
  ///  仅在非release下有效 release模式下，默认就是使用第一次注册的
  /// 为了保证v2升级到v3 未来移除
  @Deprecated('will remove , v3.0.0')
  static bool doNotAssertProviderProducer = false;

  /// 用来快速定位 viewModelProviderProducer 的提供者 保证唯一性 提升性能
  static const ViewModelProviderProducerCompanion producer =
      ViewModelProviderProducerCompanion._();

  /// 用来注册viewModel的 创建器 和默认寄存位置
  static const ViewModelFactoriesCompanion factories =
      ViewModelFactoriesCompanion._();
}

extension ViewModelExt on ViewModel {
  /// 添加一个自动清理的回调
  void onDispose(void Function() onDispose) {
    makeLiveCancellable().onCancel.then((_) => onDispose());
  }

  /// 生成一个基于viewModel生命周期的cancellable
  Cancellable makeCloseable() => makeLiveCancellable();

  Cancellable makeLiveCancellable({Cancellable? other}) => _cancellable
      .makeCancellable(father: other, infectious: false, weakRef: false);
}

extension _ViewModelClean on ViewModel {
  // 执行清理
  void clear() {
    if (_cancellable.isUnavailable) return;
    _cancellable.cancel();
    onCleared();
    _debugPrintViewModelCleared(this);
  }
}

/// ViewModel的Store
class ViewModelStore {
  final Map<Object, ViewModel> _mMap = HashMap();

  /// 放入一个ViewModel 如果已经存在则上一个执行清理
  void put<VM extends ViewModel>(VM viewModel, {Type? vmType}) {
    vmType ??= VM;
    ViewModel? oldViewModel = _mMap[vmType];
    _mMap[vmType] = viewModel;

    if (oldViewModel != null) {
      oldViewModel.clear();
    }
  }

  /// 获取ViewModel
  VM? get<VM extends ViewModel>({Type? vmType}) {
    vmType ??= VM;
    final r = _mMap[vmType];
    assert(r == null || r is VM, '$vmType must be $VM or a subclass of $VM');
    return r as VM?;
  }

  /// 获取ViewModel
  VM? remove<VM extends ViewModel>({Type? vmType}) {
    assert(() {
      Object? oldViewModel = _mMap[vmType];
      if (vmType != null && oldViewModel != null) {
        return oldViewModel is VM;
      }
      return true;
    }(), '$vmType must be $VM or a subclass of $VM');

    vmType ??= VM;
    Object? oldViewModel = _mMap.remove(vmType);
    if (oldViewModel is ViewModel) {
      oldViewModel.clear();
    }
    return oldViewModel as VM?;
  }

  /// 当前已存在的KEY
  Set<Object> keys() {
    return Set.of(_mMap.keys);
  }

  ///Clears internal storage and notifies ViewModels that they are no longer used.
  void clear() {
    if (_mMap.isNotEmpty) {
      for (ViewModel vm in [..._mMap.values]) {
        vm.clear();
      }
      _mMap.clear();
    }
  }
}

/// ViewModel创建器1
typedef ViewModelFactory<VM extends ViewModel> = VM Function();

/// ViewModel创建器2
typedef ViewModelFactory2<VM extends ViewModel> = VM Function(Lifecycle);

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
  @Deprecated('use getOrCreateViewModel')
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

  /// 使用当前的Provider获取或创建一个 ViewModel
  /// [lifecycle] 调用时的lifecycle 不一定是寄存的
  VM getOrCreateViewModel<VM extends ViewModel>(Lifecycle lifecycle,
      {ViewModelFactory<VM>? factory,
      ViewModelFactory2<VM>? factory2,
      Type? vmType}) {
    if (vmType == null) {
      // 保持兼容性 未来移除
      // ignore: deprecated_member_use_from_same_package
      return getOrCreate<VM>(lifecycle, factory: factory, factory2: factory2);
    }

    var vmCache = _viewModelStore.get<VM>(vmType: vmType);
    if (vmCache != null) return vmCache;
    VM? vm = ViewModelProvider.newInstanceViewModel(_lifecycle,
        factories: _factoryMap,
        factory: factory,
        factory2: factory2,
        vmType: vmType);
    if (vm != null) {
      _viewModelStore.put<VM>(vm, vmType: vmType);
      return vm;
    }
    throw 'cannot find $vmType factory';
  }

  /// 添加一个创建器1
  void addFactory<VM extends ViewModel>(ViewModelFactory<VM> factory) =>
      _factoryMap[VM] = factory;

  /// 添加一个创建器2
  void addFactory2<VM extends ViewModel>(ViewModelFactory2<VM> factory) =>
      _factoryMap[VM] = factory;

  static ViewModelProviderProducer? _viewModelProviderProducer;

  /// viewModels的提供者 指定为基于路由 路由页面内唯一
  @Deprecated('use ViewModel.producer.byRoute , v3.0.0')
  static ViewModelProviderProducer get producerByRoute =>
      ViewModel.producer.byRoute;

  /// viewModels的提供者 基于App app内唯一
  @Deprecated('use ViewModel.producer.byApp , v3.0.0')
  static ViewModelProviderProducer get producerByApp =>
      ViewModel.producer.byApp;

  /// 使用提供的创建工厂来创建VM 对象
  /// [lifecycle] viewModel 所寄存的lifecycle
  static VM? newInstanceViewModel<VM extends ViewModel>(Lifecycle lifecycle,
      {Map<Type, Function>? factories,
      ViewModelFactory<VM>? factory,
      ViewModelFactory2<VM>? factory2,
      Type? vmType}) {
    VM? result;
    result = factory?.call();
    result ??= factory2?.call(lifecycle);
    _debugPrintViewModelCreated(result, lifecycle, factory, factory2);
    if (result == null && factories != null) {
      result = _newInstanceViewModel<VM>(factories, lifecycle, vmType);
    }
    result ??= _newInstanceViewModel<VM>(
        _ViewModelDefFactories._instance._factoryMap, lifecycle, vmType);

    if (result != null) {
      result._lifecycle = WeakReference(lifecycle);
      result.onCreate(lifecycle);
    }
    return result;
  }
}

VM? _newInstanceViewModel<VM extends ViewModel>(
    Map<Type, Function> factories, Lifecycle lifecycle, Type? vmType) {
  VM? vm;
  Function? factory;
  if (vmType != null) {
    factory = factories[vmType];
  } else {
    factory = factories[VM];
  }
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
