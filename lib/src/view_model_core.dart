part of 'view_model.dart';

class _ViewModelDefFactories {
  static final _ViewModelDefFactories _instance = _ViewModelDefFactories();

  final Map<Type, Function> _factoryMap = HashMap();
  final Map<Type, ViewModelProviderProducer> _producerMap = HashMap();

  void addFactory<VM extends ViewModel>(ViewModelFactory<VM> factory,
      {ViewModelProviderProducer? producer}) {
    _factoryMap[VM] = factory;
    if (producer != null) {
      registerViewModelProviderProducer(producer);
    }
  }

  void addFactory2<VM extends ViewModel>(ViewModelFactory2<VM> factory,
      {ViewModelProviderProducer? producer}) {
    _factoryMap[VM] = factory;
    if (producer != null) {
      registerViewModelProviderProducer(producer);
    }
  }

  void registerViewModelProviderProducer<VM extends ViewModel>(
      ViewModelProviderProducer producer) {
    assert(!_producerMap.containsKey(VM));
    _producerMap[VM] = producer;
  }

  static ViewModelProviderProducer _getProducer<VM extends ViewModel>(
      ViewModelProviderProducer producer) {
    return _ViewModelDefFactories._instance._producerMap
        .putIfAbsent(VM, () => producer);
  }
}
