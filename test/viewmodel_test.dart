import 'package:an_viewmodel/an_viewmodel.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:flutter_test/flutter_test.dart';

import 'viewmodules.dart';

void main() {
  setUpAll(() {
    ViewModel.factories
        .addFactory(TestViewModel.new, producer: ViewModel.producer.byCurr);
    ViewModel.factories
        .addFactory(TestRefViewModel.new, producer: ViewModel.producer.byRef);
  });

  group('viewmodels', () {
    late LifecycleOwnerMock app;
    setUp(() {
      app = LifecycleOwnerMock('app');
      app.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);
    });
    tearDown(() {
      // 走完所有的生命周期
      if (app.currentLifecycleState > LifecycleState.destroyed) {
        app.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
      }
    });

    test('owner.getViewModelProvider()', () {
      final provider = app.getViewModelProvider();
      final provider2 = app.getViewModelProvider();
      expect(provider, equals(provider2));

      final lifecycle = app.lifecycle;
      final provider3 = lifecycle.owner.getViewModelProvider();
      expect(provider, equals(provider3));
    });

    test('viewModels()', () {
      final vm = app.viewModels<TestViewModel>();
      final vm1 = app.viewModels<TestViewModel>();
      expect(vm, equals(vm1));

      final vm2 = app.lifecycle.viewModels<TestViewModel>();
      expect(vm, equals(vm2));

      final provider = app.getViewModelProvider();

      final store = provider.viewModelStore;
      expect(store.get<TestViewModel>(), equals(vm));
    });

    test('provider lifecycle', () {
      final provider = app.getViewModelProvider();

      final store = provider.viewModelStore;

      final vm = app.viewModels<TestViewModel>();
      expect(store.keys(), unorderedEquals([TestViewModel]));

      app.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      expect(store.keys(), unorderedEquals([TestViewModel]));

      app.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.stop);
      expect(store.keys(), unorderedEquals([TestViewModel]));

      app.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
      expect(store.keys(), isEmpty);

      app.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);
      final provider2 = app.getViewModelProvider();

      final store2 = provider2.viewModelStore;
      final vm2 = app.viewModels<TestViewModel>();

      expect(provider2, isNot(equals(provider)));
      expect(store2, isNot(equals(store)));
      expect(store2.keys(), unorderedEquals([TestViewModel]));

      expect(vm2, isNot(equals(vm)));
    });

    test('viewModel lifecycle', () {
      final vm = app.viewModels<TestViewModel>();
      final liveable = vm.makeCloseable();

      expect(vm.isCallCleared, isFalse);
      expect(liveable.isAvailable, isTrue);

      app.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      expect(vm.isCallCleared, isFalse);
      expect(liveable.isAvailable, isTrue);

      app.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.stop);
      expect(vm.isCallCleared, isFalse);
      expect(liveable.isAvailable, isTrue);

      app.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
      expect(liveable.isAvailable, isFalse);
      expect(vm.isCallCleared, isTrue);

      expect(vm.makeCloseable().isAvailable, isFalse);

      app.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);
      final vm2 = app.viewModels<TestViewModel>();
      expect(vm2, isNot(equals(vm)));
    });

    test('viewModel lifecycle , app destroy', () {
      app.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);

      LifecycleOwnerMock scope1 = LifecycleOwnerMock('scope1');
      scope1.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.create);
      scope1.lifecycleRegistry.bindParentLifecycle(app.lifecycle);

      final vm = scope1.viewModels<TestViewModel>();
      expect(vm.isCallCleared, isFalse);

      app.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
      expect(vm.isCallCleared, isTrue);
    });

    test('.viewModels() lifecycle Env change', () {
      LifecycleOwnerMock scope = LifecycleOwnerMock('scope');
      scope.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.create);
      scope.lifecycleRegistry.bindParentLifecycle(app.lifecycle);

      final vm1 = app.viewModels<TestViewModel>();
      final vm2 = scope.viewModels<TestViewModel>();
      expect(vm1, isNot(equals(vm2)));
    });
  });

  group('byRef', () {
    /// 需要一个app 模拟最顶层的 owner
    /// 然后其他的lifecycleOwner 都通过bindParentLifecycle绑定到这个顶
    late LifecycleOwnerMock app;
    late LifecycleOwnerMock scope1;
    late LifecycleOwnerMock scope2;

    setUp(() {
      app = LifecycleOwnerMock('app');
      app.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);

      scope1 = LifecycleOwnerMock('scope1');
      scope1.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.create);
      scope1.lifecycleRegistry.bindParentLifecycle(app.lifecycle);

      scope2 = LifecycleOwnerMock('scope2');
      scope2.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.create);
      scope2.lifecycleRegistry.bindParentLifecycle(app.lifecycle);
    });

    tearDown(() {
      // 走完所有的生命周期
      if (app.currentLifecycleState > LifecycleState.destroyed) {
        app.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
      }
    });

    test('provider', () {
      final provider1 = app.getRefViewModelProvider();
      final provider2 = scope1.getRefViewModelProvider();
      final provider3 = scope2.getRefViewModelProvider();
      expect(provider1, equals(provider2));
      expect(provider1, equals(provider3));
    });

    test('viewModels', () {
      final vm1 = app.viewModels<TestRefViewModel>();
      final vm2 = scope1.viewModels<TestRefViewModel>();
      final vm3 = scope2.viewModels<TestRefViewModel>();
      final vm4 = scope2.viewModelsByRef<TestRefViewModel>();
      expect(vm1, equals(vm2));
      expect(vm1, equals(vm3));
      expect(vm1, equals(vm4));
    });

    test('provider lifecycle', () {});

    test('viewModel lifecycle', () {
      final vm1 = app.viewModels<TestRefViewModel>();
      final vm2 = scope1.viewModels<TestRefViewModel>();
      final vm3 = scope2.viewModels<TestRefViewModel>();

      expect(vm1, equals(vm2));
      expect(vm1, equals(vm3));

      expect(vm1.isCallCleared, isFalse);

      scope2.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
      expect(vm1.isCallCleared, isFalse);
      scope1.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
      expect(vm1.isCallCleared, isFalse);

      app.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
      expect(vm1.isCallCleared, isTrue);
    });

    test('viewModel lifecycle not has app', () {
      final vm1 = scope1.viewModels<TestRefViewModel>();
      final vm2 = scope2.viewModels<TestRefViewModel>();

      expect(vm1, equals(vm2));

      expect(vm1.isCallCleared, isFalse);

      scope2.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
      expect(vm1.isCallCleared, isFalse);
      scope1.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
      expect(vm1.isCallCleared, isTrue);
    });

    test('viewModel lifecycle , app destroy', () {
      final vm1 = scope1.viewModels<TestRefViewModel>();
      final vm2 = scope2.viewModels<TestRefViewModel>();

      expect(vm1, equals(vm2));

      expect(vm1.isCallCleared, isFalse);

      app.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
      expect(vm1.isCallCleared, isTrue);
    });
  });

  group('viewModelProviderProducer', () {
    late LifecycleOwnerMock app;
    setUp(() {
      app = LifecycleOwnerMock('app');
      app.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.start);
    });
    tearDown(() {
      // 走完所有的生命周期
      if (app.currentLifecycleState > LifecycleState.destroyed) {
        app.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
      }
    });

    test('.viewModels() Producer ', () {
      ViewModel.factories.addFactory(Test3ViewModel.new);

      final scope = LifecycleOwnerMock('scope');
      scope.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.create);
      scope.lifecycleRegistry.bindParentLifecycle(app.lifecycle);

      ViewModelProvider producer(LifecycleOwner owner) =>
          owner.findViewModelProvider<LifecycleOwner>(
              testLifecycleOwner: (owner) => owner.scope == 'app');

      final vm1 =
          app.viewModels<Test3ViewModel>(viewModelProviderProducer: producer);
      final vm2 =
          scope.viewModels<Test3ViewModel>(viewModelProviderProducer: producer);

      expect(vm1, equals(vm2));

      Object? err;
      try {
        final vm3 = scope.viewModels<Test3ViewModel>();
      } catch (error) {
        err = error;
      }
      expect(err, isNull,
          reason: 'viewModelProviderProducer Already registered');

      scope.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
      expect(vm1.isCallCleared, isFalse);
      expect(vm2.isCallCleared, isFalse);

      app.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
      expect(vm1.isCallCleared, isTrue);
    });

    test('.viewModels() producer conflict', () {
      ViewModel.factories.addFactory(Test4ViewModel.new);

      final scope = LifecycleOwnerMock('scope');
      scope.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.create);
      scope.lifecycleRegistry.bindParentLifecycle(app.lifecycle);

      final scope2 = LifecycleOwnerMock('scope2');
      scope2.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.create);
      scope2.lifecycleRegistry.bindParentLifecycle(app.lifecycle);

      ViewModelProvider producer(LifecycleOwner owner) =>
          owner.findViewModelProvider<LifecycleOwner>(
              testLifecycleOwner: (owner) => owner.scope == 'app');

      final vm = scope.viewModels<Test4ViewModel>(
          viewModelProviderProducer: ViewModel.producer.byCurr);
      Object? err;
      try {
        final vm2 = scope2.viewModels<Test4ViewModel>(
            viewModelProviderProducer: producer);
      } catch (error) {
        err = error;
      }
      expect(err, isNotNull,
          reason: 'viewModelProviderProducer conflict with already registered');
      expect(vm.isCallCleared, isFalse);
    });

    test('.viewModels() producer conflict but but the same lifecycle', () {
      /// 后一个的执行结果与注册的 使用了同一个ViewModelProvider 是被允许的
      /// 虽然可以执行 但不推荐使用 非常容易混淆
      ViewModel.factories.addFactory(Test5ViewModel.new);

      final scope = LifecycleOwnerMock('scope');
      scope.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.create);
      scope.lifecycleRegistry.bindParentLifecycle(app.lifecycle);

      ViewModelProvider producer(LifecycleOwner owner) =>
          owner.findViewModelProvider<LifecycleOwner>(
              testLifecycleOwner: (owner) => owner.scope == 'app');

      final vm =
          scope.viewModels<Test5ViewModel>(viewModelProviderProducer: producer);
      Object? err;
      try {
        final vm2 = app.viewModels<Test5ViewModel>(
            viewModelProviderProducer: ViewModel.producer.byCurr);
      } catch (error) {
        err = error;
      }
      expect(err, isNull,
          reason:
              'Conflict, but ultimately pointing to the same lifecycle is permitted');
      expect(vm.isCallCleared, isFalse);
    });
  });
}
