part of 'vm_ext.dart';

extension ViewModelAsyncValueNotifierSupportExt on ViewModel {
  /// 创建一个自管理的 ValueNotifier 数据源为 Stream
  /// onError 为空时 忽略 error 的处理
  /// [notifyWhenEquals] true 时，只要调用赋值行为就会发出通知 listen event 就会通知
  @Deprecated('user valueNotifierAsyncV , v3.8.0')
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
  @Deprecated('user valueNotifierAsync , v3.8.0')
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
  @Deprecated('user valueNotifierAsyncV , v3.8.0')
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
  @Deprecated('user valueNotifierAsync , v3.8.0')
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
  @Deprecated('user valueNotifierAsyncV , v3.8.0')
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
  @Deprecated('user valueNotifierAsync , v3.8.0')
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
