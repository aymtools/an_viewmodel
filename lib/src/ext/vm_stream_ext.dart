part of 'vm_ext.dart';

extension StreamBindViewModelExt<T> on Stream<T> {
  /// 与ViewModel的生命周期关联
  Stream<T> bindViewModel(ViewModel viewModel) =>
      bindCancellable(viewModel.makeLiveCancellable(weakRef: true));
}

// extension ViewModelStreamStateInExt<T> on Stream<T> {
//   ValueNotifier<T> stateIn(
//       {required ViewModel vm,
//         LifecycleState stated = LifecycleState.created,
//         T? initial,
//         T Function(Object error, StackTrace stackTrace)? onError}) {
//     if(stated<LifecycleState.started){
//       return collectAsState(initial: initial, onError: onError, cancellable: vm.makeCloseable());
//     }
//
//     vm.useHostLifecycle((l)=>bindLifecycle);
//     return bindLifecycle(lifecycle)
//   }
// }
