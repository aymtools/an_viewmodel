import 'package:an_viewmodel/src/ext/vm_ext.dart';
import 'package:an_viewmodel/src/view_model.dart';
import 'package:flutter/widgets.dart';

class _MergingValueNotifier<T> extends ValueNotifier<T> {
  final Iterable<ValueNotifier> _children;
  final T Function() _merge;

  ///
  /// [awayNotify]任何children 发出的 notify 是否 触发当前的 notifyListeners
  /// 即 即使合并后的结果相同 依然发出通知更新
  _MergingValueNotifier(this._children, this._merge, [bool awayNotify = false])
      : super(_merge()) {
    _notifyListeners = awayNotify ? _notifyListeners2 : _notifyListeners1;

    for (var c in _children) {
      c.addListener(_notifyListeners);
    }
  }

  late void Function() _notifyListeners;

  void _notifyListeners1() {
    value = _merge();
  }

  void _notifyListeners2() {
    final last = value;
    final curr = _merge();
    value = curr;

    if (last == curr) {
      /// 如果不同 上面的赋值就会触发 notifyListeners
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (var c in _children) {
      c.removeListener(_notifyListeners);
    }
    super.dispose();
  }
}

extension ViewModelValueNotifierMergeExt on ViewModel {
  /// 将多个 ValueNotifier 合并
  /// [awayNotify] 任何 源 发出的 notify 事件 是否 触发合并后的 ValueNotifier 的 notifyListeners
  @protected
  ValueNotifier<R> valueNotifierMerge<R, T1, T2>(
      {required ValueNotifier<T1> source1,
      required ValueNotifier<T2> source2,
      required R Function(T1, T2) merge,
      bool awayNotify = false}) {
    final source = _MergingValueNotifier<R>(
      [
        source1,
        source2,
      ],
      () => merge(
        source1.value,
        source2.value,
      ),
      awayNotify,
    );

    return valueNotifierSource(source);
  }

  /// 将多个 ValueNotifier 合并
  /// [awayNotify] 任何 源 发出的 notify 事件 是否 触发合并后的 ValueNotifier 的 notifyListeners
  @protected
  ValueNotifier<R> valueNotifierMerge3<R, T1, T2, T3>(
      {required ValueNotifier<T1> source1,
      required ValueNotifier<T2> source2,
      required ValueNotifier<T3> source3,
      required R Function(T1, T2, T3) merge,
      bool awayNotify = false}) {
    final source = _MergingValueNotifier<R>(
      [
        source1,
        source2,
        source3,
      ],
      () => merge(
        source1.value,
        source2.value,
        source3.value,
      ),
      awayNotify,
    );

    return valueNotifierSource(source);
  }

  /// 将多个 ValueNotifier 合并
  /// [awayNotify] 任何 源 发出的 notify 事件 是否 触发合并后的 ValueNotifier 的 notifyListeners
  @protected
  ValueNotifier<R> valueNotifierMerge4<R, T1, T2, T3, T4>(
      {required ValueNotifier<T1> source1,
      required ValueNotifier<T2> source2,
      required ValueNotifier<T3> source3,
      required ValueNotifier<T4> source4,
      required R Function(T1, T2, T3, T4) merge,
      bool awayNotify = false}) {
    final source = _MergingValueNotifier<R>(
      [
        source1,
        source2,
        source3,
        source4,
      ],
      () => merge(
        source1.value,
        source2.value,
        source3.value,
        source4.value,
      ),
      awayNotify,
    );

    return valueNotifierSource(source);
  }

  /// 将多个 ValueNotifier 合并
  /// [awayNotify] 任何 源 发出的 notify 事件 是否 触发合并后的 ValueNotifier 的 notifyListeners
  @protected
  ValueNotifier<R> valueNotifierMerge5<R, T1, T2, T3, T4, T5>(
      {required ValueNotifier<T1> source1,
      required ValueNotifier<T2> source2,
      required ValueNotifier<T3> source3,
      required ValueNotifier<T4> source4,
      required ValueNotifier<T5> source5,
      required R Function(T1, T2, T3, T4, T5) merge,
      bool awayNotify = false}) {
    final source = _MergingValueNotifier<R>(
      [
        source1,
        source2,
        source3,
        source4,
        source5,
      ],
      () => merge(
        source1.value,
        source2.value,
        source3.value,
        source4.value,
        source5.value,
      ),
      awayNotify,
    );

    return valueNotifierSource(source);
  }

  /// 将多个 ValueNotifier 合并
  /// [awayNotify] 任何 源 发出的 notify 事件 是否 触发合并后的 ValueNotifier 的 notifyListeners
  @protected
  ValueNotifier<R> valueNotifierMerge6<R, T1, T2, T3, T4, T5, T6>(
      {required ValueNotifier<T1> source1,
      required ValueNotifier<T2> source2,
      required ValueNotifier<T3> source3,
      required ValueNotifier<T4> source4,
      required ValueNotifier<T5> source5,
      required ValueNotifier<T6> source6,
      required R Function(T1, T2, T3, T4, T5, T6) merge,
      bool awayNotify = false}) {
    final source = _MergingValueNotifier<R>(
      [
        source1,
        source2,
        source3,
        source4,
        source5,
        source6,
      ],
      () => merge(
        source1.value,
        source2.value,
        source3.value,
        source4.value,
        source5.value,
        source6.value,
      ),
      awayNotify,
    );

    return valueNotifierSource(source);
  }

  /// 将多个 ValueNotifier 合并
  /// [awayNotify] 任何 源 发出的 notify 事件 是否 触发合并后的 ValueNotifier 的 notifyListeners
  @protected
  ValueNotifier<R> valueNotifierMerge7<R, T1, T2, T3, T4, T5, T6, T7>(
      {required ValueNotifier<T1> source1,
      required ValueNotifier<T2> source2,
      required ValueNotifier<T3> source3,
      required ValueNotifier<T4> source4,
      required ValueNotifier<T5> source5,
      required ValueNotifier<T6> source6,
      required ValueNotifier<T7> source7,
      required R Function(T1, T2, T3, T4, T5, T6, T7) merge,
      bool awayNotify = false}) {
    final source = _MergingValueNotifier<R>(
      [
        source1,
        source2,
        source3,
        source4,
        source5,
        source6,
        source7,
      ],
      () => merge(
        source1.value,
        source2.value,
        source3.value,
        source4.value,
        source5.value,
        source6.value,
        source7.value,
      ),
      awayNotify,
    );

    return valueNotifierSource(source);
  }

  /// 将多个 ValueNotifier 合并
  /// [awayNotify] 任何 源 发出的 notify 事件 是否 触发合并后的 ValueNotifier 的 notifyListeners
  @protected
  ValueNotifier<R> valueNotifierMerge8<R, T1, T2, T3, T4, T5, T6, T7, T8>(
      {required ValueNotifier<T1> source1,
      required ValueNotifier<T2> source2,
      required ValueNotifier<T3> source3,
      required ValueNotifier<T4> source4,
      required ValueNotifier<T5> source5,
      required ValueNotifier<T6> source6,
      required ValueNotifier<T7> source7,
      required ValueNotifier<T8> source8,
      required R Function(T1, T2, T3, T4, T5, T6, T7, T8) merge,
      bool awayNotify = false}) {
    final source = _MergingValueNotifier<R>(
      [
        source1,
        source2,
        source3,
        source4,
        source5,
        source6,
        source7,
        source8,
      ],
      () => merge(
        source1.value,
        source2.value,
        source3.value,
        source4.value,
        source5.value,
        source6.value,
        source7.value,
        source8.value,
      ),
      awayNotify,
    );

    return valueNotifierSource(source);
  }

  /// 将多个 ValueNotifier 合并
  /// [awayNotify] 任何 源 发出的 notify 事件 是否 触发合并后的 ValueNotifier 的 notifyListeners
  @protected
  ValueNotifier<R> valueNotifierMerge9<R, T1, T2, T3, T4, T5, T6, T7, T8, T9>(
      {required ValueNotifier<T1> source1,
      required ValueNotifier<T2> source2,
      required ValueNotifier<T3> source3,
      required ValueNotifier<T4> source4,
      required ValueNotifier<T5> source5,
      required ValueNotifier<T6> source6,
      required ValueNotifier<T7> source7,
      required ValueNotifier<T8> source8,
      required ValueNotifier<T9> source9,
      required R Function(T1, T2, T3, T4, T5, T6, T7, T8, T9) merge,
      bool awayNotify = false}) {
    final source = _MergingValueNotifier<R>(
      [
        source1,
        source2,
        source3,
        source4,
        source5,
        source6,
        source7,
        source8,
        source9,
      ],
      () => merge(
        source1.value,
        source2.value,
        source3.value,
        source4.value,
        source5.value,
        source6.value,
        source7.value,
        source8.value,
        source9.value,
      ),
      awayNotify,
    );

    return valueNotifierSource(source);
  }
}
