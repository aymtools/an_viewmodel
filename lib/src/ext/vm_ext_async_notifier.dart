part of 'vm_ext.dart';

extension ViewModelAsyncValueNotifierExt on ViewModel {
  /// 创建一个自管理的 ValueNotifier 类型为 AsyncData
  /// [notifyWhenEquals] true 时，只要调用赋值行为就会发出通知
  @protected
  ValueNotifier<AsyncData<T>> valueNotifierAsync<T>(
      {T? initialData,
      bool initialAllowNull = false,
      Object? error,
      StackTrace? stackTrace,
      Future<T>? future,
      Stream<T>? stream,
      bool? cancelOnError,
      bool notifyWhenEquals = false}) {
    _ValueNotifier<AsyncData<T>> notifier;
    if (initialData != null || initialAllowNull) {
      notifier = _ValueNotifier(
          this, AsyncData<T>.value(initialData as T), notifyWhenEquals);
    } else if (error != null) {
      notifier = _ValueNotifier(
          this, AsyncData<T>.error(error, stackTrace), notifyWhenEquals);
    } else {
      notifier = _ValueNotifier(this, AsyncData<T>.loading(), notifyWhenEquals);
    }

    future
        ?.bindCancellable(makeLiveCancellable(weakRef: false))
        .then(notifier.toValue, onError: notifier.toError);

    stream?.bindViewModel(this).listen(
          notifier.toValue,
          onError: notifier.toError,
          cancelOnError: cancelOnError,
        );

    return notifier;
  }

  /// 创建一个自管理的 ValueNotifier 数据源为 Future
  /// onError 为空时 忽略 error 的处理
  ValueNotifier<T> valueNotifierAsyncV<T>({
    required T initialData,
    Future<T>? future,
    Stream<T>? stream,
    bool? cancelOnError,
    Function? onError,
    T Function(ValueNotifier<T>, Object error, StackTrace stackTrace)?
        returnOnError,
    bool notifyWhenEquals = false,
  }) {
    ValueNotifier<T> result =
        _ValueNotifier(this, initialData, notifyWhenEquals);

    future?.bindCancellable(makeLiveCancellable(weakRef: false)).then(
      (event) => result.value = event,
      onError: (Object e, StackTrace s) {
        if (returnOnError != null) {
          result.value = returnOnError(result, e, s);
        }
        onError?.call(e, s);
      },
    );

    stream?.bindViewModel(this).listen(
      (event) => result.value = event,
      onError: (Object error, StackTrace stackTrace) {
        if (returnOnError != null) {
          result.value = returnOnError(result, error, stackTrace);
        }
        if (onError != null) {
          if (onError is dynamic Function(Object, StackTrace)) {
            onError(error, stackTrace);
          } else if (onError is dynamic Function(Object)) {
            onError(error);
          } else {
            throw ArgumentError.value(
                onError,
                "onError",
                "Error handler must accept one Object or one Object and a StackTrace"
                    " as arguments, and return a value of the returned type");
          }
        }
      },
      cancelOnError: cancelOnError,
    );

    return result;
  }

  /// 创建一个自管理的 ValueNotifier 数据源为 sync Future Or sync stream
  /// onError 为空时 忽略 error 的处理
  ValueNotifier<T> valueNotifierSyncV<T>({
    Future<T>? future,
    Stream<T>? stream,
    bool? cancelOnError,
    Function? onError,
    T Function(ValueNotifier<T>?, Object error, StackTrace stackTrace)?
        returnOnError,
    T Function(Object error, StackTrace stackTrace)? returnOnError2,
    bool notifyWhenEquals = false,
  }) {
    ValueNotifier<T>? result;

    void createOrSet(T value) {
      if (result == null) {
        result = _ValueNotifier(this, value, notifyWhenEquals);
      } else {
        result?.value = value;
      }
    }

    future?.bindCancellable(makeLiveCancellable(weakRef: false)).then(
      createOrSet,
      onError: (Object e, StackTrace s) {
        if (returnOnError != null) {
          createOrSet(returnOnError(result, e, s));
        } else if (returnOnError2 != null) {
          createOrSet(returnOnError2(e, s));
        }
        onError?.call(e, s);
      },
    );

    stream?.bindViewModel(this).listen(
      createOrSet,
      onError: (Object error, StackTrace stackTrace) {
        if (returnOnError != null) {
          createOrSet(returnOnError(result, error, stackTrace));
        }
        if (onError != null) {
          if (onError is dynamic Function(Object, StackTrace)) {
            onError(error, stackTrace);
          } else if (onError is dynamic Function(Object)) {
            onError(error);
          } else {
            throw ArgumentError.value(
                onError,
                "onError",
                "Error handler must accept one Object or one Object and a StackTrace"
                    " as arguments, and return a value of the returned type");
          }
        }
      },
      cancelOnError: cancelOnError,
    );

    return result!;
  }
}
