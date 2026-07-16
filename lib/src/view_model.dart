import 'dart:collection';

import 'package:anlifecycle/anlifecycle.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/widgets.dart';
import 'package:weak_collections/weak_collections.dart';

part 'view_model_callback.dart';

part 'view_model_companion.dart';

part 'view_model_core.dart';

part 'view_model_tools.dart';

/// ViewModel基类
abstract mixin class ViewModel {
  final Cancellable _cancellable = Cancellable();
  WeakReference<Lifecycle>? _lifecycle;
  WeakReference<Lifecycle Function()>? _hostLifecycle;

  /// 调用完构造函数之后调用 初始化创建
  /// [lifecycle] 当前ViewModel所寄存的 [lifecycle]
  /// * 早于[onCreated]调用，由于所寄存的[lifecycle]会变动，创建后传入并不合适，后续如需使用当前寄存的[lifecycle]，请使用 [useHostLifecycle]
  @Deprecated('use onCreated, will remove , v3.8.0')
  @protected
  void onCreate(Lifecycle lifecycle) {}

  /// 调用完构造函数之后调用 实例已经完成初始化
  @protected
  void onCreated() {}

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
  static const ViewModelProviderProducerCompanion producer = producers;

  /// 用来快速定位 viewModelProviderProducer 的提供者 保证唯一性 提升性能
  static const ViewModelProviderProducerCompanion producers =
      ViewModelProviderProducerCompanion._();

  /// 用来注册viewModel的 创建器 和默认寄存位置
  static const ViewModelFactoriesCompanion factories =
      ViewModelFactoriesCompanion._();
}

/// 稳定抛出ViewModel状态异常的错误
Never _throwViewModelClearedError() {
  throw StateError('ViewModel is cleared');
}

extension ViewModelExt on ViewModel {
  /// 添加一个自动清理的回调
  void onDispose(void Function() onDispose) {
    makeLiveCancellable(weakRef: false).onCancel.then((_) => onDispose());
  }

  /// 生成一个基于viewModel生命周期的cancellable
  /// - 默认强关联
  Cancellable makeCloseable() => makeLiveCancellable(weakRef: false);

  /// 生成一个基于viewModel生命周期的cancellable
  Cancellable makeLiveCancellable({Cancellable? other, bool weakRef = true}) =>
      _cancellable.makeCancellable(
          father: other, infectious: false, weakRef: weakRef);

  /// 判断当前 viewmodel isCleared
  bool get isCleared => _cancellable.isUnavailable;

  /// 使用宿主的[lifecycle]，
  /// 推荐使用[lifecycle]后不要持有引用，用完即弃
  T useHostLifecycle<T>(
      {required T Function(Lifecycle) block,
      T Function() onCleared = _throwViewModelClearedError}) {
    if (isCleared) return onCleared();
    final lifecycle = _hostLifecycle?.target?.call() ?? _lifecycle?.target;
    if (lifecycle == null) return onCleared();
    return block(lifecycle);
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
      _clearViewModel(oldViewModel);
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
      _clearViewModel(oldViewModel);
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
        _clearViewModel(vm);
      }
      _mMap.clear();
    }
  }

  /// 检查是否包含viewModle
  bool containsValue(ViewModel vm) => _mMap.containsValue(vm);
}

/// ViewModel创建器1
typedef ViewModelFactory<VM extends ViewModel> = VM Function();

/// ViewModel创建器2
typedef ViewModelFactory2<VM extends ViewModel> = VM Function(Lifecycle);

/// 用来管理如何创建ViewModel
class ViewModelProvider {
  final ViewModelStore _viewModelStore = ViewModelStore();
  final WeakReference<Lifecycle> _lifecycle;
  final Map<Type, Function> _factoryMap = HashMap();

  ViewModelProvider(Lifecycle lifecycle)
      : _lifecycle = WeakReference(lifecycle) {
    lifecycle.addLifecycleObserver(LifecycleObserver.eventDestroy(() {
      _viewModelStore.clear();
      _factoryMap.clear();
    }));
  }

  @visibleForTesting
  @protected
  ViewModelStore get viewModelStore => _viewModelStore;

  @visibleForTesting
  @protected
  Lifecycle get lifecycle => _lifecycle.target!;

  // 用来提供给viewModel的获取hostLifecycle
  // Lifecycle _hostLifecycle() => _lifecycle.target!;

  /// 使用当前的Provider获取或创建一个 ViewModel
  /// [lifecycle] 调用时的lifecycle 不一定是寄存的
  @Deprecated('use getOrCreateViewModel')
  VM getOrCreate<VM extends ViewModel>(Lifecycle lifecycle,
      {ViewModelFactory<VM>? factory, ViewModelFactory2<VM>? factory2}) {
    var vmCache = _viewModelStore.get<VM>();
    if (vmCache != null) return vmCache;
    VM? vm = ViewModelProvider.newInstanceViewModel(this.lifecycle,
        factories: _factoryMap,
        factory: factory,
        factory2: factory2,
        provider: this);
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
    VM? vm = ViewModelProvider.newInstanceViewModel(this.lifecycle,
        factories: _factoryMap,
        factory: factory,
        factory2: factory2,
        provider: this,
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
  /// [provider] 为了保证旧版本的兼容性可以允许为空 目前只在[ViewModelCallbacks.instance]中使用
  static VM? newInstanceViewModel<VM extends ViewModel>(Lifecycle lifecycle,
      {Map<Type, Function>? factories,
      ViewModelFactory<VM>? factory,
      ViewModelFactory2<VM>? factory2,
      ViewModelProvider? provider,
      Type? vmType}) {
    VM? result;
    result = factory?.call();
    result ??= factory2?.call(lifecycle);
    if (result == null && factories != null) {
      result = _newInstanceViewModel<VM>(factories, lifecycle, vmType);
    }
    result ??= _newInstanceViewModel<VM>(
        _ViewModelDefFactories._instance._factoryMap, lifecycle, vmType);

    if (result != null) {
      if (provider != null) {
        result._lifecycle = WeakReference(lifecycle);
      }
      ViewModelCallbacks.instance._onInstantiated(result, provider, lifecycle);
      _safeCallViewModelMethod(
          // ignore: deprecated_member_use_from_same_package
          result, (vm) => vm.onCreate(lifecycle), 'onCreate');
      _safeCallViewModelMethod(result, (vm) => vm.onCreated(), 'onCreated');
      ViewModelCallbacks.instance._onCreated(result, provider, lifecycle);
    }
    return result;
  }

  /// 替换 viewModel的 hostLifecycle 提供器
  /// [vm] 必须为当前Provider创建的ViewModel
  /// [newHostLifecycle] 函数自身必须是强引用 匿名函数会导致设置失效
  @protected
  void changeViewModelHostLifecycle(
      ViewModel vm, Lifecycle Function() newHostLifecycle) {
    if (_viewModelStore.containsValue(vm)) {
      vm._hostLifecycle = WeakReference(newHostLifecycle);
    }
  }

  /// 重置 viewModel的 hostLifecycle 提供器
  /// [vm] 必须为当前Provider创建的ViewModel
  @protected
  void resetViewModelHostLifecycle(ViewModel vm) {
    if (_viewModelStore.containsValue(vm)) vm._hostLifecycle = null;
  }
}

void _safeCallViewModelMethod(
    ViewModel viewModel, void Function(ViewModel) invoker, String methodName) {
  try {
    invoker(viewModel);
  } catch (e, s) {
    FlutterError.reportError(FlutterErrorDetails(
      exception: e,
      stack: s,
      library: 'an_viewmodel',
      context: ErrorDescription('while calling $methodName of $viewModel'),
    ));
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
  } else if (factory is ViewModelFactory2<VM>) {
    vm = factory(lifecycle);
  }
  return vm;
}

void _clearViewModel<VM extends ViewModel>(VM vm) {
  if (vm._cancellable.isUnavailable) return;
  vm._cancellable.cancel();
  // vm.onCleared();
  _safeCallViewModelMethod(vm, (vm) => vm.onCleared(), 'onCleared');
  ViewModelCallbacks.instance._onCleared(vm);
}
