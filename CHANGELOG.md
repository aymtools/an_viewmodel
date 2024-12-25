## 2.0.0

- Added makeCloseable to provide cancelable based on viewmodel lifecycle.

### Breaking Changes

- viewModels(factory,factory2) : Parameters factory and factory2 are no longer automatically added
  to ViewModelProvider to prevent memory leaks
- viewModelsByRef(factory2) : The lifecycle parameter of factory2 is changed to AppLifecycle

## 1.0.0

- Migrate from an_lifecycle_viewmodel.
