import 'package:flutter/widgets.dart';

part 'async_data.dart';

extension AsyncDataNotifierTypedExt<T extends Object>
    on ValueNotifier<AsyncData<T>> {
  bool get isLoading => value.isLoading;

  bool get hasError => value.hasError;

  bool get hasData => value.hasData;

  T get data => value.data;

  T? get dataOrNull => hasData ? data : null;

  Object get error => value.error;

  StackTrace? get stackTrace => value.stackTrace;

  R when<R>({
    required R Function() loading,
    required R Function(T data) value,
    required R Function(Object error, StackTrace? stackTrace) error,
  }) =>
      this.value.when<R>(loading: loading, value: value, error: error);

  void toLoading() => value = value._toLoading();

  void toValue(T data) => value = value._toValue(data);

  void toError(Object error, [StackTrace? stackTrace]) =>
      value = value._toError(error, stackTrace);
}
