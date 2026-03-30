part of 'view_model.dart';

typedef ViewModelCreatedCallback = void Function(
    ViewModel vm, ViewModelProvider? provider, Lifecycle hostLifecycle);
typedef ViewModelClearedCallback = void Function(ViewModel vm);

/// 所有注册的callback 都是直接调用 没有try catch function中如果有异常会直接影响框架的运行。
/// **请勿直接强引用所有回调中的的[ViewModel],[Lifecycle],[ViewModelProvider]会影响回收逻辑**
class ViewModelCallbacks {
  ViewModelCallbacks._() {
    assert(() {
      if (ViewModel.printLifecycle) {
        _PrintViewModelLifecycle i = _PrintViewModelLifecycle();
        addInstantiatedCallback(i._onInstantiated);
        addCreatedCallback(i._onCreated);
        addClearedCallback(i._onCleared);
      }
      return true;
    }());
  }

  static final ViewModelCallbacks _instance = ViewModelCallbacks._();

  static ViewModelCallbacks get instance => _instance;

  final Set<ViewModelCreatedCallback> _instantiatedCallbacks = {};
  final Set<ViewModelCreatedCallback> _createdCallbacks = {};
  final Set<ViewModelClearedCallback> _clearedCallbacks = {};

  /// 调用 [factory] 生成对象后调用
  void addInstantiatedCallback(ViewModelCreatedCallback callback) {
    _instantiatedCallbacks.add(callback);
  }

  /// 调用 [factory] 生成对象后调用
  void removeInstantiatedCallback(ViewModelCreatedCallback callback) {
    _instantiatedCallbacks.remove(callback);
  }

  /// 调用完 [viewModel.onCreate] 后调用
  void addCreatedCallback(ViewModelCreatedCallback callback) {
    _createdCallbacks.add(callback);
  }

  /// 调用完 [viewModel.onCreate] 后调用
  void removeCreatedCallback(ViewModelCreatedCallback callback) {
    _createdCallbacks.remove(callback);
  }

  /// 调用完 [viewModel.onCleared] 后调用
  void addClearedCallback(ViewModelClearedCallback callback) {
    _clearedCallbacks.add(callback);
  }

  /// 调用完 [viewModel.onCleared] 后调用
  void removeClearedCallback(ViewModelClearedCallback callback) {
    _clearedCallbacks.remove(callback);
  }

  void _onInstantiated(
      ViewModel vm, ViewModelProvider? provider, Lifecycle hostLifecycle) {
    final callbacks = Set<ViewModelCreatedCallback>.of(_instantiatedCallbacks);
    for (var c in callbacks) {
      c(vm, provider, hostLifecycle);
    }
  }

  void _onCreated(
      ViewModel vm, ViewModelProvider? provider, Lifecycle hostLifecycle) {
    final callbacks = Set<ViewModelCreatedCallback>.of(_createdCallbacks);
    for (var c in callbacks) {
      c(vm, provider, hostLifecycle);
    }
  }

  void _onCleared(ViewModel vm) {
    final callbacks = Set<ViewModelClearedCallback>.of(_clearedCallbacks);
    for (var c in callbacks) {
      c(vm);
    }
  }
}

class _PrintViewModelLifecycle {
  /// 调用 [factory] 生成对象后调用
  void _onInstantiated(
      ViewModel vm, ViewModelProvider? provider, Lifecycle hostLifecycle) {
    String providerStr = provider == null
        ? ''
        : 'Provider ${provider.runtimeType}:${provider.hashCode}';
    final owner = hostLifecycle.owner;
    String hostStr =
        '${owner.runtimeType}${owner.scope ?? ''}:${owner.hashCode}';

    debugPrint('ViewModel: ${vm.runtimeType}:${vm.hashCode} Instantiated '
        'By $hostStr $providerStr');
  }

  /// 调用完 [viewModel.onCreate] 后调用
  void _onCreated(
      ViewModel vm, ViewModelProvider? provider, Lifecycle hostLifecycle) {
    String providerStr = provider == null
        ? ''
        : 'Provider ${provider.runtimeType}:${provider.hashCode}';
    final owner = hostLifecycle.owner;
    String hostStr =
        '${owner.runtimeType}${owner.scope ?? ''}:${owner.hashCode}';

    debugPrint('ViewModel: ${vm.runtimeType}:${vm.hashCode} Created '
        'By $hostStr $providerStr');
  }

  /// 调用完 [viewModel.onCleared] 后调用
  void _onCleared(ViewModel vm) {
    debugPrint('ViewModel: ${vm.runtimeType}:${vm.hashCode} Cleared');
  }
}
