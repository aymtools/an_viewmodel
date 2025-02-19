part of 'vm_ext.dart';

extension ViewModelValueNotifierAdvancedExt on ViewModel {
  /// 转换到另一类型 单向 不可反向赋值
  @protected
  ValueNotifier<R> valueNotifierTransform<R, S>(
      {required ValueNotifier<S> source, required R Function(S) transformer}) {
    final ValueNotifier<R> result = valueNotifier<R>(transformer(source.value));

    source.addCListener(
        makeCloseable(), () => result.value = transformer(source.value));

    return result;
  }
}
