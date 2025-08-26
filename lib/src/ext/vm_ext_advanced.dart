part of 'vm_ext.dart';

extension ViewModelValueNotifierAdvancedExt on ViewModel {
  /// 转换到另一类型 单向 不可反向赋值
  @protected
  ValueNotifier<R> valueNotifierTransform<R, S>(
      {required ValueNotifier<S> source, required R Function(S) transformer}) {
    final ValueNotifier<R> result = valueNotifier<R>(transformer(source.value));
    if (isCleared) {
      return result;
    }

    void listener() => result.value = transformer(source.value);

    source.addListener(listener);
    makeLiveCancellable(weakRef: false)
        .whenCancel
        .then((_) => source.removeListener(listener));

    return result;
  }
}
