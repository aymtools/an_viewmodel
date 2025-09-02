import 'package:an_viewmodel/an_viewmodel.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:test/test.dart';

import 'viewmodules.dart';

void main() {
  setUpAll(() {
    ViewModel.printLifecycle = false;
    ViewModel.factories
        .addFactory(TestViewModel.new, producer: ViewModel.producer.byCurr);
    ViewModel.factories
        .addFactory(Test2ViewModel.new, producer: ViewModel.producer.byCurr);
  });

  group('ViewModel', () {
    late LifecycleOwnerMock app;
    setUp(() {
      app = LifecycleOwnerMock('app');
      app.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.create);
    });

    tearDown(() {
      if (app.currentLifecycleState > LifecycleState.destroyed) {
        app.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
      }
    });

    test('.viewModels()', () {
      final vm1 = app.viewModels<TestViewModel>();
      final vm2 = app.viewModels<Test2ViewModel>();
      final vm3 = vm1.viewModels<Test2ViewModel>();
      expect(vm2, equals(vm3));
    });

    test('.makeLiveCancellable()', () {
      final vm = app.viewModels<TestViewModel>();
      final cancellable = vm.makeLiveCancellable();

      expect(vm.isCallCleared, isFalse);
      expect(cancellable.isAvailable, isTrue);

      app.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);

      expect(vm.isCallCleared, isTrue);
      expect(cancellable.isAvailable, isFalse);
    });
  });
}
