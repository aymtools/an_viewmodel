import 'package:an_viewmodel/src/view_model.dart';
import 'package:flutter/widgets.dart';

import 'vm_ext.dart';

extension ViewModelValueNotifierAdvancedExt on ViewModel {
  /// 转换到另一类型
  @protected
  ValueNotifier<R> valueNotifierTransform<R, S>(
      {required ValueNotifier<S> source, required R Function(S) transformer}) {
    final ValueNotifier<R> result = valueNotifier<R>(transformer(source.value));
    void onChange() {
      result.value = transformer(source.value);
    }

    source.addListener(onChange);
    onDispose(() => source.removeListener(onChange));
    return result;
  }
}
