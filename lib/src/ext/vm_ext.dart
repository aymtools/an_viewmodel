import 'dart:async';

import 'package:an_async_data/an_async_data.dart';
import 'package:an_viewmodel/src/view_model.dart';
import 'package:cancellable/cancellable.dart';
import 'package:flutter/foundation.dart';

part 'vm_ext_advanced.dart';

part 'vm_ext_merge.dart';

part 'vm_stream_ext.dart';

part 'vm_ext_async_notifier.dart';
part 'vm_ext_async_notifier_s.dart';

/// viewModel 销毁时 set value 不在发出通知
class _ValueNotifier<T> extends ValueNotifier<T> {
  final Cancellable _cancellable;
  final bool notifyWhenEquals;
  T _value;

  _ValueNotifier(ViewModel vm, this._value, [this.notifyWhenEquals = false])
      : _cancellable = vm.makeLiveCancellable(weakRef: true),
        super(_value) {
    _cancellable.whenCancel.then((_) => super.dispose());
  }

  @override
  T get value => _value;

  @override
  set value(T newValue) {
    if (_cancellable.isAvailable) {
      if (_value == newValue) {
        if (notifyWhenEquals) {
          super.notifyListeners();
        }
        return;
      }
      _value = newValue;
      super.notifyListeners();
    } else {
      // 仅仅赋值不通知
      _value = newValue;
    }
  }

  @override
  void addListener(VoidCallback listener) {
    if (_cancellable.isAvailable) {
      super.addListener(listener);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    if (_cancellable.isAvailable) {
      super.removeListener(listener);
    }
  }

  @override
  void notifyListeners() {
    if (_cancellable.isAvailable) {
      super.notifyListeners();
    }
  }

  @override
  // ignore: must_call_super
  void dispose() {
    _cancellable.cancel();
  }
}

extension ViewModelValueNotifierExt on ViewModel {
  /// 将提供的源 绑定到生命周期
  /// [bindSource] 是否将当前的值反向赋值到source 默认为true
  @protected
  ValueNotifier<T> valueNotifierSource<T>(ValueNotifier<T> source,
      {bool autoDisposeSource = true, bool bindSource = true}) {
    final cancellable = makeLiveCancellable(weakRef: false);

    if (autoDisposeSource) {
      cancellable.whenCancel.then((_) => source.dispose());
    }
    final result = valueNotifier(source.value);
    if (isCleared) {
      return result;
    }

    void listener() => result.value = source.value;
    source.addListener(listener);
    cancellable.onCancel.then((_) => source.removeListener(listener));

    if (bindSource) {
      void listener2() => source.value = result.value;
      result.addListener(listener2);

      /// 由于是_ValueNotifier 无须反向解绑
      //cancellable.onCancel.then((_) => result.removeListener(listener2));
    }
    return result;
  }

  /// 创建一个自管理的 ValueNotifier
  @protected
  ValueNotifier<T> valueNotifier<T>(T value) {
    return _ValueNotifier(this, value);
  }

}

// extension ViewModelValueNotifierCallExt on ViewModel {
//   ValueNotifier<T> call<T>(T data) {
//     return valueNotifier(data);
//   }
// }
