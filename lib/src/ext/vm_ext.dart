import 'dart:async';

import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/widgets.dart';

import '../view_model.dart';
import 'value_notifier_ext.dart';

part 'vm_ext_advanced.dart';
part 'vm_ext_merge.dart';

/// viewModel 销毁时不在可用setValue
class _ViewModelValueNotifier<T> extends ValueNotifier<T> {
  final Cancellable _cancellable;

  _ViewModelValueNotifier(ViewModel vm, super.value)
      : _cancellable = vm.makeCloseable();

  @override
  set value(T newValue) {
    if (_cancellable.isAvailable) {
      super.value = newValue;
    }
  }
}

extension ViewModelValueNotifierExt on ViewModel {
  /// 将提供的源 绑定到生命周期
  /// [bindSource] 是否将当前的值反向赋值到source 默认为true
  @protected
  ValueNotifier<T> valueNotifierSource<T>(ValueNotifier<T> source,
      {bool autoDisposeSource = true, bool bindSource = true}) {
    final cancellable = makeCloseable();
    if (autoDisposeSource) {
      source.bindCancellable(cancellable);
    }
    final result = valueNotifier(source.value);

    source.addCListener(cancellable, () => result.value = source.value);
    if (bindSource) {
      result.addCListener(cancellable, () => source.value = result.value);
    }

    return result;
  }

  /// 创建一个自管理的 ValueNotifier
  @protected
  ValueNotifier<T> valueNotifier<T>(T value) {
    return _ViewModelValueNotifier(this, value);
  }

  /// 创建一个自管理的 ValueNotifier 类型为 AsyncData
  @protected
  ValueNotifier<AsyncData<T>> valueNotifierAsync<T extends Object>(
      {T? initialData, Object? error, StackTrace? stackTrace}) {
    if (initialData != null) {
      return valueNotifier(AsyncData<T>.value(initialData));
    } else if (error != null) {
      return valueNotifier(AsyncData<T>.error(error, stackTrace));
    }
    return valueNotifier(AsyncData<T>.loading());
  }

  /// 创建一个自管理的 ValueNotifier 数据源为 Stream
  /// onError 为空时 忽略 error 的处理
  @protected
  ValueNotifier<T> valueNotifierStream<T extends Object>(
      {required Stream<T> stream,
      required T initialData,
      Function? onError,
      bool? cancelOnError}) {
    final result = valueNotifier(initialData);
    stream.bindCancellable(makeCloseable()).listen(
          (event) => result.value = event,
          onError: onError,
          cancelOnError: cancelOnError,
        );
    return result;
  }

  /// 创建一个自管理的 ValueNotifier 类型为 AsyncData 数据源为 Stream
  @protected
  ValueNotifier<AsyncData<T>> valueNotifierAsyncStream<T extends Object>(
      {Stream<T>? stream, T? initialData, bool? cancelOnError}) {
    final result = valueNotifierAsync<T>(initialData: initialData);
    stream?.bindCancellable(makeCloseable()).listen(
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
        .bindCancellable(makeCloseable())
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
        ?.bindCancellable(makeCloseable())
        .then(result.toValue, onError: result.toError);
    return result;
  }

  /// 创建一个自管理的 ValueNotifier 数据源为 StreamController
  /// onError 为空时 忽略 error 的处理
  @protected
  ValueNotifier<T> valueNotifierStreamController<T extends Object>(
          {required StreamController<T> streamController,
          required T initialData,
          Function? onError,
          bool? cancelOnError}) =>
      valueNotifierStream(
          stream: streamController.stream.repeatLatest(),
          initialData: initialData,
          onError: onError,
          cancelOnError: cancelOnError);

  /// 创建一个自管理的 ValueNotifier 类型为 AsyncData 数据源为 StreamController
  @protected
  ValueNotifier<AsyncData<T>>
      valueNotifierAsyncStreamController<T extends Object>(
              {StreamController<T>? streamController,
              T? initialData,
              bool? cancelOnError}) =>
          valueNotifierAsyncStream(
              stream: streamController?.stream.repeatLatest(),
              initialData: initialData,
              cancelOnError: cancelOnError);
}
