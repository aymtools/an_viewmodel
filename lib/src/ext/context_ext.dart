import 'dart:async';

import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:flutter/widgets.dart';

import '../view_model.dart';

final _keyLifecycleAndViewModelEffect = Object();

typedef LifecycleAndViewModelEffectTask<VM extends ViewModel> = FutureOr
    Function(Lifecycle lifecycle, VM vm);

extension BuildContextWithLifecycleAndViewModelEffectExt on BuildContext {
  ///允许基于当前context和viewmodel执行生命周期相关的函数
  VM withLifecycleAndViewModelEffect<VM extends ViewModel>({
    VM? data,
    VM Function()? factory,
    VM Function(Lifecycle lifecycle)? factory2,
    LifecycleAndViewModelEffectTask<VM>? launchOnFirstCreate,
    LifecycleAndViewModelEffectTask<VM>? launchOnFirstStart,
    LifecycleAndViewModelEffectTask<VM>? launchOnFirstResume,
    LifecycleAndViewModelEffectTask<VM>? launchOnDestroy,
    LifecycleAndViewModelEffectTask<VM>? repeatOnStarted,
    LifecycleAndViewModelEffectTask<VM>? repeatOnResumed,
    ViewModelProvider Function(LifecycleOwner lifecycleOwner)?
        viewModelProvider,
  }) {
    return withLifecycleEffectData(
      factory2: (lifecycle) => lifecycle.viewModels(
          factory: data == null ? factory : () => data,
          factory2: factory2,
          viewModelProvider: viewModelProvider),
      key: _keyLifecycleAndViewModelEffect,
      launchOnFirstCreate: launchOnFirstCreate,
      launchOnFirstStart: launchOnFirstStart,
      launchOnFirstResume: launchOnFirstResume,
      launchOnDestroy: launchOnDestroy,
      repeatOnStarted: repeatOnStarted,
      repeatOnResumed: repeatOnResumed,
    );
  }
}
