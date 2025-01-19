import 'dart:async';

import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:an_viewmodel/src/view_model.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:cancellable/cancellable.dart';

extension ViewModeLToolsExt on ViewModeL {
  /// 可继续获取 viewModel 但只能获取平级 或者更上一层的
  VM viewModels<VM extends ViewModel>(
      {ViewModelFactory<VM>? factory,
      ViewModelFactory2<VM>? factory2,
      ViewModelProvider Function(LifecycleOwner lifecycleOwner)?
          viewModelProvider}) {
    return lifecycle.viewModels(
        factory: factory,
        factory2: factory2,
        viewModelProvider: viewModelProvider);
  }

  /// 获取最近的Route提供的 viewModelProvider 来获取 ViewModel
  VM viewModelsByRoute<VM extends ViewModel>(
          {ViewModelFactory<VM>? factory, ViewModelFactory2<VM>? factory2}) =>
      viewModels(
          factory: factory,
          factory2: factory2,
          viewModelProvider: (owner) => owner.getViewModelProviderByRoute());

  /// 获取基于App的ViewModel
  VM viewModelsByApp<VM extends ViewModel>(
          {ViewModelFactory<VM>? factory, ViewModelFactory2<VM>? factory2}) =>
      viewModels(
          factory: factory,
          factory2: factory2,
          viewModelProvider: (owner) => owner.getViewModelProviderByApp());

  /// 当高于某个状态时执行给定的block
  void repeatOnLifecycle<T>(
          {LifecycleState targetState = LifecycleState.started,
          bool runWithDelayed = false,
          Cancellable? cancellable,
          required FutureOr<T> Function(Cancellable cancellable) block}) =>
      lifecycle.repeatOnLifecycle(
          targetState: targetState,
          runWithDelayed: runWithDelayed,
          cancellable: cancellable,
          block: block);

  ///当高于某个状态时执行给定的block,并将结构收集起来为Stream
  Stream<T> collectOnLifecycle<T>(
          {LifecycleState targetState = LifecycleState.started,
          bool runWithDelayed = false,
          Cancellable? cancellable,
          required FutureOr<T> Function(Cancellable cancellable) block}) =>
      lifecycle.collectOnLifecycle(
          targetState: targetState,
          runWithDelayed: runWithDelayed,
          cancellable: cancellable,
          block: block);

  /// 当下一个事件分发时，执行一次给定的block
  Future<T> launchWhenNextLifecycleEvent<T>(
          {LifecycleEvent targetEvent = LifecycleEvent.start,
          bool runWithDelayed = false,
          Cancellable? cancellable,
          required FutureOr<T> Function(Cancellable cancellable) block}) =>
      lifecycle.launchWhenNextLifecycleEvent(
          targetEvent: targetEvent,
          runWithDelayed: runWithDelayed,
          cancellable: cancellable,
          block: block);

  /// 当高于某个状态时，执行一次给定的block
  Future<T> launchWhenLifecycleStateAtLeast<T>(
          {LifecycleState targetState = LifecycleState.started,
          bool runWithDelayed = false,
          Cancellable? cancellable,
          required FutureOr<T> Function(Cancellable cancellable) block}) =>
      lifecycle.launchWhenLifecycleStateAtLeast(
          targetState: targetState,
          runWithDelayed: runWithDelayed,
          cancellable: cancellable,
          block: block);

  void repeatOnLifecycleStarted<T>(
          {bool runWithDelayed = false,
          Cancellable? cancellable,
          required FutureOr<T> Function(Cancellable cancellable) block}) =>
      repeatOnLifecycle(
          targetState: LifecycleState.started,
          runWithDelayed: runWithDelayed,
          cancellable: cancellable,
          block: block);

  void repeatOnLifecycleResumed<T>(
          {bool runWithDelayed = false,
          Cancellable? cancellable,
          required FutureOr<T> Function(Cancellable cancellable) block}) =>
      repeatOnLifecycle(
          targetState: LifecycleState.resumed,
          runWithDelayed: runWithDelayed,
          cancellable: cancellable,
          block: block);

  Stream<T> collectOnLifecycleStarted<T>(
          {bool runWithDelayed = false,
          Cancellable? cancellable,
          required FutureOr<T> Function(Cancellable cancellable) block}) =>
      collectOnLifecycle(
          targetState: LifecycleState.started,
          runWithDelayed: runWithDelayed,
          cancellable: cancellable,
          block: block);

  Stream<T> collectOnLifecycleResumed<T>(
          {bool runWithDelayed = false,
          Cancellable? cancellable,
          required FutureOr<T> Function(Cancellable cancellable) block}) =>
      collectOnLifecycle(
          targetState: LifecycleState.resumed,
          runWithDelayed: runWithDelayed,
          cancellable: cancellable,
          block: block);

  Future<T> launchWhenNextLifecycleEventStart<T>(
          {bool runWithDelayed = false,
          Cancellable? cancellable,
          required FutureOr<T> Function(Cancellable cancellable) block}) =>
      launchWhenNextLifecycleEvent(
          targetEvent: LifecycleEvent.start,
          runWithDelayed: runWithDelayed,
          cancellable: cancellable,
          block: block);

  Future<T> launchWhenNextLifecycleEventResume<T>(
          {bool runWithDelayed = false,
          Cancellable? cancellable,
          required FutureOr<T> Function(Cancellable cancellable) block}) =>
      launchWhenNextLifecycleEvent(
          targetEvent: LifecycleEvent.resume,
          runWithDelayed: runWithDelayed,
          cancellable: cancellable,
          block: block);

  Future<T> launchWhenLifecycleStateStarted<T>(
          {bool runWithDelayed = false,
          Cancellable? cancellable,
          required FutureOr<T> Function(Cancellable cancellable) block}) =>
      launchWhenLifecycleStateAtLeast(
          targetState: LifecycleState.started,
          runWithDelayed: runWithDelayed,
          cancellable: cancellable,
          block: block);

  Future<T> launchWhenLifecycleStateResumed<T>(
          {bool runWithDelayed = false,
          Cancellable? cancellable,
          required FutureOr<T> Function(Cancellable cancellable) block}) =>
      launchWhenLifecycleStateAtLeast(
          targetState: LifecycleState.resumed,
          runWithDelayed: runWithDelayed,
          cancellable: cancellable,
          block: block);

  Future<T> launchWhenLifecycleStateDestroyed<T>(
          {bool runWithDelayed = false,
          Cancellable? cancellable,
          required FutureOr<T> Function(Cancellable cancellable) block}) =>
      lifecycle.launchWhenLifecycleStateDestroyed(
          runWithDelayed: runWithDelayed,
          cancellable: cancellable,
          block: block);

  Future<T> launchWhenLifecycleEventDestroy<T>(
          {bool runWithDelayed = false,
          Cancellable? cancellable,
          required FutureOr<T> Function(Cancellable cancellable) block}) =>
      lifecycle.launchWhenLifecycleEventDestroy(
          runWithDelayed: runWithDelayed,
          cancellable: cancellable,
          block: block);
}
