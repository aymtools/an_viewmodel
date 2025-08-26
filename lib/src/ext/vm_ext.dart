import 'dart:async';

import 'package:cancellable/cancellable.dart';
import 'package:flutter/foundation.dart';

import '../view_model.dart';
import 'value_notifier_ext.dart';

part 'vm_ext_advanced.dart';
part 'vm_ext_merge.dart';
part 'vm_stream_ext.dart';

/// viewModel 销毁时 set value 不在发出通知
class _ValueNotifier<T> extends ValueNotifier<T> {
  final Cancellable _cancellable;
  final bool notifyWhenEquals;
  T _value;

  _ValueNotifier(ViewModel vm, this._value, [this.notifyWhenEquals = false])
      : _cancellable = vm.makeLiveCancellable(weakRef: true),
        super(_value) {
    _cancellable.whenCancel.then((_) => super.dispose());
  }

  @override
  T get value => _value;

  @override
  set value(T newValue) {
    if (_cancellable.isAvailable) {
      if (_value == newValue) {
        if (notifyWhenEquals) {
          super.notifyListeners();
        }
        return;
      }
      _value = newValue;
      super.notifyListeners();
    } else {
      // 仅仅赋值不通知
      _value = newValue;
    }
  }

  @override
  void addListener(VoidCallback listener) {
    if (_cancellable.isAvailable) {
      super.addListener(listener);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    if (_cancellable.isAvailable) {
      super.removeListener(listener);
    }
  }

  @override
  void notifyListeners() {
    if (_cancellable.isAvailable) {
      super.notifyListeners();
    }
  }

  @override
  // ignore: must_call_super
  void dispose() {
    _cancellable.cancel();
  }
}

extension ViewModelValueNotifierExt on ViewModel {
  /// 将提供的源 绑定到生命周期
  /// [bindSource] 是否将当前的值反向赋值到source 默认为true
  @protected
  ValueNotifier<T> valueNotifierSource<T>(ValueNotifier<T> source,
      {bool autoDisposeSource = true, bool bindSource = true}) {
    final cancellable = makeLiveCancellable(weakRef: false);

    if (autoDisposeSource) {
      cancellable.whenCancel.then((_) => source.dispose());
    }
    final result = valueNotifier(source.value);
    if (isCleared) {
      return result;
    }

    void listener() => result.value = source.value;
    source.addListener(listener);
    cancellable.onCancel.then((_) => source.removeListener(listener));

    if (bindSource) {
      void listener2() => source.value = result.value;
      result.addListener(listener2);

      /// 由于是_ValueNotifier 无须反向解绑
      //cancellable.onCancel.then((_) => result.removeListener(listener2));
    }
    return result;
  }

  /// 创建一个自管理的 ValueNotifier
  @protected
  ValueNotifier<T> valueNotifier<T>(T value) {
    return _ValueNotifier(this, value);
  }

  /// 创建一个自管理的 ValueNotifier 类型为 AsyncData
  /// [notifyWhenEquals] true 时，只要调用赋值行为就会发出通知
  @protected
  ValueNotifier<AsyncData<T>> valueNotifierAsync<T extends Object>(
      {T? initialData,
      Object? error,
      StackTrace? stackTrace,
      bool notifyWhenEquals = false}) {
    if (initialData != null) {
      return _ValueNotifier(
          this, AsyncData<T>.value(initialData), notifyWhenEquals);
    } else if (error != null) {
      return _ValueNotifier(
          this, AsyncData<T>.error(error, stackTrace), notifyWhenEquals);
    }
    return _ValueNotifier(this, AsyncData<T>.loading(), notifyWhenEquals);
  }

  /// 创建一个自管理的 ValueNotifier 数据源为 Stream
  /// onError 为空时 忽略 error 的处理
  /// [notifyWhenEquals] true 时，只要调用赋值行为就会发出通知 listen event 就会通知
  @protected
  ValueNotifier<T> valueNotifierStream<T extends Object>(
      {required Stream<T> stream,
      required T initialData,
      Function? onError,
      bool? cancelOnError,
      bool notifyWhenEquals = false}) {
    final result = _ValueNotifier(this, initialData, notifyWhenEquals);
    stream.bindViewModel(this).listen(
          (event) => result.value = event,
          onError: onError,
          cancelOnError: cancelOnError,
        );
    return result;
  }

  /// 创建一个自管理的 ValueNotifier 类型为 AsyncData 数据源为 Stream
  /// [notifyWhenEquals] true 时，只要调用赋值行为就会发出通知 listen event 就会通知
  @protected
  ValueNotifier<AsyncData<T>> valueNotifierAsyncStream<T extends Object>(
      {Stream<T>? stream,
      T? initialData,
      bool? cancelOnError,
      bool notifyWhenEquals = false}) {
    final result = valueNotifierAsync<T>(
        initialData: initialData, notifyWhenEquals: notifyWhenEquals);
    stream?.bindViewModel(this).listen(
          result.toValue,
          onError: result.toError,
          cancelOnError: cancelOnError,
        );
    return result;
  }

  /// 创建一个自管理的 ValueNotifier 数据源为 Future
  /// onError 为空时 忽略 error 的处理
  @protected
  ValueNotifier<T> valueNotifierFuture<T extends Object>(
      {required Future<T> future, required T initialData, Function? onError}) {
    final result = valueNotifier(initialData);
    future
        .bindCancellable(makeLiveCancellable(weakRef: false))
        .then((event) => result.value = event, onError: onError);
    return result;
  }

  /// 创建一个自管理的 ValueNotifier 类型为 AsyncData 数据源为 Future
  @protected
  ValueNotifier<AsyncData<T>> valueNotifierAsyncFuture<T extends Object>({
    Future<T>? future,
    T? initialData,
  }) {
    final result = valueNotifierAsync<T>(initialData: initialData);
    future
        ?.bindCancellable(makeLiveCancellable(weakRef: false))
        .then(result.toValue, onError: result.toError);
    return result;
  }

  /// 创建一个自管理的 ValueNotifier 数据源为 StreamController
  /// onError 为空时 忽略 error 的处理
  /// [notifyWhenEquals] true 时，只要调用赋值行为就会发出通知 listen event 就会通知
  @protected
  ValueNotifier<T> valueNotifierStreamController<T extends Object>(
          {required StreamController<T> streamController,
          required T initialData,
          Function? onError,
          bool? cancelOnError,
          bool notifyWhenEquals = false}) =>
      valueNotifierStream(
          stream: streamController.stream,
          initialData: initialData,
          onError: onError,
          cancelOnError: cancelOnError,
          notifyWhenEquals: notifyWhenEquals);

  /// 创建一个自管理的 ValueNotifier 类型为 AsyncData 数据源为 StreamController
  /// [notifyWhenEquals] true 时，只要调用赋值行为就会发出通知 listen event 就会通知
  @protected
  ValueNotifier<AsyncData<T>>
      valueNotifierAsyncStreamController<T extends Object>(
              {StreamController<T>? streamController,
              T? initialData,
              bool? cancelOnError,
              bool notifyWhenEquals = false}) =>
          valueNotifierAsyncStream(
              stream: streamController?.stream,
              initialData: initialData,
              cancelOnError: cancelOnError,
              notifyWhenEquals: notifyWhenEquals);
}

// extension ViewModelValueNotifierCallExt on ViewModel {
//   ValueNotifier<T> call<T>(T data) {
//     return valueNotifier(data);
//   }
// }
