import 'dart:async';

import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:an_viewmodel/an_viewmodel.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/cupertino.dart';

/// 定义一个基于异步状态的数据结构
abstract class AsyncData<T extends Object> {
  AsyncData._();

  factory AsyncData.loading() => AsyncDataLoading<T>._();

  factory AsyncData.value(T value) => AsyncDataValue<T>._(value);

  factory AsyncData.error(Object error, [StackTrace? stackTrace]) =>
      AsyncDataError<T>._(error, stackTrace);
}

/// 加载中
class AsyncDataLoading<T extends Object> extends AsyncData<T> {
  AsyncDataLoading._() : super._();

  @override
  int get hashCode => Object.hash(AsyncDataLoading, T);

  @override
  bool operator ==(Object other) => other is AsyncDataLoading<T>;
}

///  加载完成 包含数据
class AsyncDataValue<T extends Object> extends AsyncData<T> {
  final T value;

  T get date => value;

  AsyncDataValue._(this.value) : super._();
}

/// 加载失败 存在异常
class AsyncDataError<T extends Object> extends AsyncData<T> {
  final Object error;
  final StackTrace? stackTrace;

  AsyncDataError._(this.error, [this.stackTrace]) : super._();

  @override
  int get hashCode => Object.hash(AsyncDataError, error, stackTrace);

  @override
  bool operator ==(Object other) =>
      other is AsyncDataError<T> &&
      other.error == error &&
      other.stackTrace == stackTrace;
}

extension AsyncDataTypedExt<T extends Object> on AsyncData<T> {
  bool get isLoading => this is AsyncDataLoading<T>;

  bool get hasError => this is AsyncDataError<T>;

  bool get hasValue => this is AsyncDataValue<T>;

  bool get hasData => hasValue;

  T get value => (this as AsyncDataValue<T>).value;

  T get data => value;

  Object get error => (this as AsyncDataError<T>).error;

  StackTrace? get stackTrace => (this as AsyncDataError<T>).stackTrace;

  R when<R>({
    required R Function() loading,
    required R Function(T data) value,
    required R Function(Object error, StackTrace? stackTrace) error,
  }) {
    if (this is AsyncDataLoading<T>) {
      return loading();
    } else if (this is AsyncDataValue<T>) {
      return value((this as AsyncDataValue<T>).data);
    } else {
      return error((this as AsyncDataError<T>).error,
          (this as AsyncDataError<T>).stackTrace);
    }
  }

  AsyncData<T> _toLoading() => this is AsyncDataLoading<T>
      ? this as AsyncDataLoading<T>
      : AsyncData<T>.loading();

  AsyncData<T> _toValue(T data) => this is AsyncDataValue<T>
      ? this as AsyncDataValue<T>
      : AsyncData<T>.value(data);

  AsyncData<T> _toError(Object error, [StackTrace? stackTrace]) =>
      this is AsyncDataError<T>
          ? this as AsyncDataError<T>
          : AsyncData<T>.error(error, stackTrace);
}

extension AsyncDataNotifierTypedExt<T extends Object>
    on ValueNotifier<AsyncData<T>> {
  bool get isLoading => value.isLoading;

  bool get hasError => value.hasError;

  bool get hasData => value.hasData;

  T get data => value.data;

  Object get error => value.error;

  StackTrace? get stackTrace => value.stackTrace;

  void when({
    required void Function() loading,
    required void Function(T data) value,
    required void Function(Object error, StackTrace? stackTrace) error,
  }) =>
      this.value.when(loading: loading, value: value, error: error);

  void toLoading() => value = value._toLoading();

  void toValue(T data) => value = value._toValue(data);

  void toError(Object error, [StackTrace? stackTrace]) =>
      value = value._toError(error, stackTrace);
}

extension ViewModelValueNotifierExt on ViewModel {
  /// 创建一个自管理的 ValueNotifier
  ValueNotifier<T> valueNotifier<T>(T value) {
    return ValueNotifier(value)..bindCancellable(makeCloseable());
  }

  /// 创建一个自管理的 ValueNotifier 类型为 AsyncData
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
  ValueNotifier<AsyncData<T>> valueNotifierAsyncStream<T extends Object>(
      Stream<T> stream,
      {T? initialData,
      bool? cancelOnError}) {
    final result = valueNotifierAsync<T>(initialData: initialData);
    stream.bindCancellable(makeCloseable()).listen(
          (event) => result.toValue(event),
          onError: (error, stackTrace) => result.toError(error, stackTrace),
          cancelOnError: cancelOnError,
        );
    return result;
  }
}
