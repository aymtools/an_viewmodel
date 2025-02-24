part of 'vm_ext.dart';

extension StreamBindViewModelExt<T> on Stream<T> {
  /// 与ViewModel的生命周期关联
  Stream<T> bindViewModel(ViewModel viewModel) =>
      bindCancellable(viewModel.makeCloseable());
}
