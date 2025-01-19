## 2.0.0

- The newly added class ViewModeL(The last letter is capitalized, appearing as Lifecycle.) needs to
  provide a Lifecycle getter.
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
