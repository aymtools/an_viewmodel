import 'dart:async';

import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:an_viewmodel/src/view_model.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:flutter/widgets.dart';

final _keyLifecycleAndViewModelEffect = Object();

typedef LifecycleAndViewModelEffectTask<VM extends ViewModel> = FutureOr
    Function(Lifecycle lifecycle, VM vm);

extension BuildContextWithLifecycleAndViewModelEffectExt on BuildContext {
  ///允许基于当前context和viewmodel执行生命周期相关的函数
  ///***
  ///特别说明 task中的Lifecycle是当前context最近的Lifecycle 并非ViewModel所寄存的Lifecycle
  @Deprecated('use viewModels() and withLifecycleEffect(), v3.3.0')
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
        viewModelProviderProducer,
  }) {
    return withLifecycleAndDataEffect(
      factory2: (lifecycle) => lifecycle.viewModels(
          factory: data == null ? factory : () => data,
          factory2: factory2,
          viewModelProviderProducer: viewModelProviderProducer),
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
