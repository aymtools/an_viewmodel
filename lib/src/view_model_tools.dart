part of 'view_model.dart';

final WeakHashMap<LifecycleOwner, ViewModelProvider> _viewModelProviderMap =
    WeakHashMap();

extension ViewModelStoreOwnerExtension on LifecycleOwner {
  /// 获取 当前的viewModelStore
  /// 由于owner中可能不仅仅存在一种 viewModelProvider 直接获取store 存在歧义 未来将会移除
  @Deprecated('use getViewModelProvider().viewModelStore , v3.3.0')
  ViewModelStore getViewModelStore() => getViewModelProvider().viewModelStore;

  /// 获取当前的 viewModelProvider
  ViewModelProvider getViewModelProvider() {
    assert(currentLifecycleState > LifecycleState.destroyed,
        'Must be used before destroyed.');
    return _viewModelProviderMap.putIfAbsent(this, () {
      addLifecycleObserver(
          LifecycleObserver.onEventDestroy(_viewModelProviderMap.remove));
      return ViewModelProvider(lifecycle);
    });
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

    //viewModelProviderProducer ??= ViewModel.producer._default;

    final producer =
        _ViewModelDefFactories._getProducer<VM>(viewModelProviderProducer);

    assert(() {
      //  ignore: deprecated_member_use_from_same_package
      if (ViewModel.doNotAssertProviderProducer) return true;
      if (viewModelProviderProducer == null ||
          producer == viewModelProviderProducer) {
        return true;
      }
      var tmp1 = producer.call(owner);
      var tmp2 = viewModelProviderProducer.call(owner);
      return tmp1 == tmp2;
    }(), 'viewModelProviderProducer already exists with different results.');

    return producer.call(owner).getOrCreateViewModel<VM>(toLifecycle(),
        factory: factory, factory2: factory2);
  }

  /// 获取基于RoutePage的ViewModel
  VM viewModelsByRoute<VM extends ViewModel>({
    ViewModelFactory<VM>? factory,
    ViewModelFactory2<VM>? factory2,
  }) =>
      viewModels<VM>(
          factory: factory,
          factory2: factory2,
          viewModelProviderProducer: ViewModel.producer.byRoute);

  /// 获取基于App的ViewModel
  VM viewModelsByApp<VM extends ViewModel>({
    ViewModelFactory<VM>? factory,
    ViewModelFactory2<VM>? factory2,
  }) =>
      viewModels<VM>(
          factory: factory,
          factory2: factory2,
          viewModelProviderProducer: ViewModel.producer.byApp);

  /// 自定义按需查找的 ViewModel
  VM viewModelsByLifecycleOwner<VM extends ViewModel,
              LO extends LifecycleOwnerStateMixin>(
          {ViewModelFactory<VM>? factory,
          ViewModelFactory2<VM>? factory2,
          bool Function(LO)? testLifecycleOwner}) =>
      viewModels<VM>(
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
      viewModels<VM>(
          factory: factory,
          factory2: factory2,
          viewModelProviderProducer: ViewModel.producer.byRoute);

  /// 获取基于App的ViewModel
  VM viewModelsByApp<VM extends ViewModel>(
          {ViewModelFactory<VM>? factory, ViewModelFactory2<VM>? factory2}) =>
      viewModels<VM>(
          factory: factory,
          factory2: factory2,
          viewModelProviderProducer: ViewModel.producer.byApp);
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

    return context.viewModels<VM>(
        factory: factory,
        factory2: factory2,
        viewModelProviderProducer:
            viewModelProviderProducer ?? viewModelProvider);
  }

  /// 获取最近的Route提供的 viewModelProvider 来获取 ViewModel
  VM viewModelsByRouteOfState<VM extends ViewModel>(
          {ViewModelFactory<VM>? factory, ViewModelFactory2<VM>? factory2}) =>
      viewModelsOfState<VM>(
          factory: factory,
          factory2: factory2,
          viewModelProviderProducer: ViewModel.producer.byRoute);

  /// 获取基于App的ViewModel
  VM viewModelsByAppOfState<VM extends ViewModel>(
          {ViewModelFactory<VM>? factory, ViewModelFactory2<VM>? factory2}) =>
      viewModelsOfState<VM>(
          factory: factory,
          factory2: factory2,
          viewModelProviderProducer: ViewModel.producer.byApp);
}

extension ViewModelViewModelsExt on ViewModel {
  /// 可以从当前viewModel 继续查找可用的View Model
  VM viewModels<VM extends ViewModel>(
      {ViewModelFactory<VM>? factory,
      ViewModelFactory2<VM>? factory2,
      ViewModelProvider Function(LifecycleOwner lifecycleOwner)?
          viewModelProviderProducer}) {
    return _lifecycle.target!.viewModels<VM>(
        factory: factory,
        factory2: factory2,
        viewModelProviderProducer: viewModelProviderProducer);
  }

  VM viewModelsByRoute<VM extends ViewModel>(
      {ViewModelFactory<VM>? factory, ViewModelFactory2<VM>? factory2}) {
    return viewModels<VM>(
        factory: factory,
        factory2: factory2,
        viewModelProviderProducer: ViewModel.producer.byRoute);
  }

  VM viewModelsByApp<VM extends ViewModel>(
      {ViewModelFactory<VM>? factory, ViewModelFactory2<VM>? factory2}) {
    return viewModels<VM>(
        factory: factory,
        factory2: factory2,
        viewModelProviderProducer: ViewModel.producer.byApp);
  }
}
