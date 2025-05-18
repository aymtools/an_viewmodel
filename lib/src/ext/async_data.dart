part of 'value_notifier_ext.dart';

/// 定义一个基于异步状态的数据结构
sealed class AsyncData<T extends Object> {
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

  T? get valueOrNull => hasValue ? value : null;

  T? get dataOrNull => valueOrNull;

  Object get error => (this as AsyncDataError<T>).error;

  StackTrace? get stackTrace => (this as AsyncDataError<T>).stackTrace;

  R when<R>({
    required R Function() loading,
    required R Function(T value) value,
    required R Function(Object error, StackTrace? stackTrace) error,
  }) {
    if (this is AsyncDataLoading<T>) {
      return loading();
    } else if (this is AsyncDataValue<T>) {
      return value((this as AsyncDataValue<T>).value);
    } else {
      return error((this as AsyncDataError<T>).error,
          (this as AsyncDataError<T>).stackTrace);
    }
  }

  AsyncData<T> _toLoading() => this is AsyncDataLoading<T>
      ? this as AsyncDataLoading<T>
      : AsyncData<T>.loading();

  AsyncData<T> _toValue(T value) =>
      (this is AsyncDataValue<T> && (this as AsyncDataValue<T>).value == value)
          ? this
          : AsyncData<T>.value(value);

  AsyncData<T> _toError(Object error, [StackTrace? stackTrace]) =>
      (this is AsyncDataError<T> &&
              (this as AsyncDataError<T>).error == error &&
              (this as AsyncDataError<T>).stackTrace == stackTrace)
          ? this
          : AsyncData<T>.error(error, stackTrace);
}
