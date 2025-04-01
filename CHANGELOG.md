## 2.1.4

- Fix the bug of clearing the ViewModel when removing from ViewModelStore.

## 2.1.3

- Print logs for ViewModel creation and cleanup in non-release mode.

## 2.1.2

- Upgrading Dependencies.

## 2.1.1

- Add more proactive notifications to valueNotifierStreamXXX when notifyWhenEquals=true.

## 2.1.0

- BuildContext.withLifecycleAndViewModelEffect allows executing lifecycle-related functions based on
  the current context and ViewModel.
- Optimize the usage of ViewModelProviderProducer.

## 2.0.0

- Added makeCloseable to provide cancelable based on viewmodel lifecycle.
- ViewModel adds extensions: valueNotifier, valueNotifierAsync, valueNotifierStream,
  valueNotifierAsyncStream, valueNotifierFuture, valueNotifierAsyncFuture,
  valueNotifierStreamController, valueNotifierAsyncStreamController, valueNotifierTransform,
  valueNotifierMerge to facilitate the rapid construction of ValueNotifiers.

### Breaking Changes

- viewModels(factory,factory2) : Parameters factory and factory2 are no longer automatically added
  to ViewModelProvider to prevent memory leaks.
- RefViewModelProvider is no longer a subclass of ViewModel.
- viewModelsByRef(factory2) : The lifecycle parameter of factory2 is changed to AppLifecycle.
- ViewModelStore : The key in ViewModelStore has been adjusted to its type.

## 1.0.0

- Migrate from an_lifecycle_viewmodel.
