part of 'view_model.dart';

/// ViewModelProvider 的创建器
typedef ViewModelProviderProducer = ViewModelProvider Function(LifecycleOwner);

class ViewModelProviderProducerCompanion {
  const ViewModelProviderProducerCompanion._();
}

extension ViewModelProviderProducerConfigCoreExt
    on ViewModelProviderProducerCompanion {
  /// 设置默认的viewModels的提供者 的创建方式
  set defaultProducer(ViewModelProviderProducer value) {
    assert(ViewModelProvider._viewModelProviderProducer == null,
        'set producerDefault can only be called once.');
    ViewModelProvider._viewModelProviderProducer = value;
  }

  ViewModelProviderProducer get _default {
    return ViewModelProvider._viewModelProviderProducer ?? byCurr;
  }

  /// viewModels的提供者 指定为基于路由 路由页面内唯一
  ViewModelProviderProducer get byRoute =>
      (owner) => owner.getViewModelProviderByRoute();

  /// viewModels的提供者 基于App app内唯一
  ViewModelProviderProducer get byApp =>
      (owner) => owner.getViewModelProviderByApp();

  /// viewModels的提供者 当前最近的Lifecycle
  ViewModelProviderProducer get byCurr =>
      (owner) => owner.getViewModelProvider();
}

class ViewModelFactoriesCompanion {
  const ViewModelFactoriesCompanion._();
}

extension ViewModelCompanionCoreExt on ViewModelFactoriesCompanion {
  /// 添加 全局的 创建器1
  void addFactory<VM extends ViewModel>(ViewModelFactory<VM> factory,
          {ViewModelProviderProducer? producer}) =>
      _ViewModelDefFactories._instance
          .addFactory<VM>(factory, producer: producer);

  /// 添加 全局的 创建器2
  void addFactory2<VM extends ViewModel>(ViewModelFactory2<VM> factory,
          {ViewModelProviderProducer? producer}) =>
      _ViewModelDefFactories._instance
          .addFactory2<VM>(factory, producer: producer);

  void registerViewModelProviderProducer<VM extends ViewModel>(
      ViewModelProviderProducer producer) {
    _ViewModelDefFactories._instance
        .registerViewModelProviderProducer<VM>(producer);
  }
}
