import 'package:an_viewmodel/an_viewmodel.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:flutter/widgets.dart';
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

    test('.valueNotifier()', () {
      final vm = app.viewModels<TestViewModel>();
      final valueNotifier1 = vm.valueNotifier<int>(0);
      final valueNotifier2 = vm.valueNotifier<int>(0);
      expect(valueNotifier1, isNot(equals(valueNotifier2)));

      var currValue = valueNotifier1.value;
      expect(currValue, 0);

      valueNotifier1.addListener(() {
        currValue = valueNotifier1.value;
      });

      valueNotifier1.value = 1;
      expect(currValue, 1);

      app.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
      expect(vm.isCallCleared, isTrue);

      valueNotifier1.value = 2;
      expect(currValue, 1,
          reason: 'after cleared, valueNotifier should not notify listener');
      expect(valueNotifier1.value, 2);
    });

    test('.valueNotifierAsyncFuture()', () async {
      final vm = app.viewModels<TestViewModel>();
      var futureCalled = false;
      final valueNotifier = vm.valueNotifierAsyncFuture<int>(
        future: Future<int>.delayed(const Duration(milliseconds: 100), () {
          futureCalled = true;
          return 42;
        }),
      );

      expect(valueNotifier.value.isLoading, isTrue);
      expect(futureCalled, isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(valueNotifier.value.isLoading, isFalse);
      expect(valueNotifier.value.hasValue, isTrue);
      expect(valueNotifier.value.value, 42);
      expect(futureCalled, isTrue);

      app.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
      expect(vm.isCallCleared, isTrue);
    });

    test('.valueNotifierAsyncStream()', () async {
      final vm = app.viewModels<TestViewModel>();
      var streamCalledCount = 0;
      final valueNotifier = vm.valueNotifierAsyncStream<int>(
        stream:
            Stream<int>.periodic(const Duration(milliseconds: 100), (count) {
          streamCalledCount++;
          return count;
        }).take(3),
      );

      expect(valueNotifier.value.isLoading, isTrue);
      expect(streamCalledCount, 0);

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(valueNotifier.value.isLoading, isFalse);
      expect(valueNotifier.value.hasValue, isTrue);
      expect(valueNotifier.value.value, 0);
      expect(streamCalledCount, 1);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(valueNotifier.value.value, 1);
      expect(streamCalledCount, 2);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(valueNotifier.value.value, 2);
      expect(streamCalledCount, 3);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(valueNotifier.value.value, 2);
      expect(streamCalledCount, 3);

      app.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
      expect(vm.isCallCleared, isTrue);
    });

    test('.valueNotifierSource()', () async {
      final vm = app.viewModels<TestViewModel>();
      final source = ValueNotifier<int>(0);
      final valueNotifier = vm.valueNotifierSource<int>(source);

      expect(valueNotifier.value, 0);

      source.value = 1;
      expect(valueNotifier.value, 1);

      valueNotifier.value = 2;
      expect(source.value, 2);

      app.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
      expect(vm.isCallCleared, isTrue);

      await Future.delayed(Duration.zero);

      Object? exception;
      try {
        source.value = 3;
      } catch (e) {
        exception = e;
      }
      expect(exception, isNotNull,
          reason:
              'after cleared, source should throw exception when set value');
      expect(valueNotifier.value, 2,
          reason: 'after cleared, valueNotifier should not notify listener');
      expect(source.value, 3);
    });

    test('.valueNotifierSource() autoDisposeSource: false ', () {
      final vm = app.viewModels<TestViewModel>();
      final source = ValueNotifier<int>(0);
      final valueNotifier =
          vm.valueNotifierSource<int>(source, autoDisposeSource: false);

      expect(valueNotifier.value, 0);

      source.value = 1;
      expect(valueNotifier.value, 1);

      app.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
      expect(vm.isCallCleared, isTrue);

      Object? exception;
      try {
        source.value = 2;
      } catch (e) {
        exception = e;
      }
      expect(exception, isNull);
      expect(valueNotifier.value, 1,
          reason: 'after cleared, valueNotifier should not notify listener');
      expect(source.value, 2);
    });

    test('.valueNotifierSource() bindSource: false ', () {
      final vm = app.viewModels<TestViewModel>();
      final source = ValueNotifier<int>(0);
      final valueNotifier =
          vm.valueNotifierSource<int>(source, bindSource: false);

      expect(valueNotifier.value, 0);

      source.value = 1;
      expect(valueNotifier.value, 1);

      valueNotifier.value = 2;
      expect(source.value, 1);
    });

    test('.valueNotifierAsync()', () {
      final vm = app.viewModels<TestViewModel>();
      var valueNotifier = vm.valueNotifierAsync<int>();

      expect(valueNotifier.value.isLoading, isTrue);
      expect(valueNotifier.value.hasData, isFalse);
      expect(valueNotifier.value.hasError, isFalse);

      valueNotifier = vm.valueNotifierAsync<int>(initialData: 1);
      expect(valueNotifier.value.isLoading, isFalse);
      expect(valueNotifier.value.hasData, isTrue);
      expect(valueNotifier.value.hasError, isFalse);

      valueNotifier = vm.valueNotifierAsync<int>(error: 'has err');
      expect(valueNotifier.value.isLoading, isFalse);
      expect(valueNotifier.value.hasData, isFalse);
      expect(valueNotifier.value.hasError, isTrue);

      valueNotifier.value = AsyncData.value(1);
      expect(valueNotifier.value.isLoading, isFalse);
      expect(valueNotifier.value.hasData, isTrue);
      expect(valueNotifier.value.hasError, isFalse);

      valueNotifier.toLoading();
      expect(valueNotifier.value.isLoading, isTrue);
      expect(valueNotifier.value.hasData, isFalse);
      expect(valueNotifier.value.hasError, isFalse);
      expect(valueNotifier.dataOrNull, isNull);

      valueNotifier.toError('err', StackTrace.current);
      expect(valueNotifier.value.isLoading, isFalse);
      expect(valueNotifier.value.hasData, isFalse);
      expect(valueNotifier.value.hasError, isTrue);
      expect(valueNotifier.dataOrNull, isNull);

      valueNotifier.toValue(2);
      expect(valueNotifier.value.isLoading, isFalse);
      expect(valueNotifier.value.hasData, isTrue);
      expect(valueNotifier.value.hasError, isFalse);

      expect(valueNotifier.data, 2);
    });
    test('.valueNotifierAsync() notifyWhenEquals: true', () {
      final vm = app.viewModels<TestViewModel>();
      var valueNotifier =
          vm.valueNotifierAsync<int>(initialData: 1, notifyWhenEquals: true);

      int notifyCount = 0;
      valueNotifier.addListener(() {
        notifyCount++;
      });
      valueNotifier.toValue(2);
      expect(notifyCount, 1);
      valueNotifier.toValue(2);
      expect(notifyCount, 2);
      valueNotifier.toValue(1);
      expect(notifyCount, 3);
    });
    test('.valueNotifierStream()', () async {
      final vm = app.viewModels<TestViewModel>();
      var streamCalledCount = 0;
      final valueNotifier = vm.valueNotifierStream<int>(
        initialData: 0,
        stream:
            Stream<int>.periodic(const Duration(milliseconds: 100), (count) {
          streamCalledCount++;
          return count;
        }).take(3),
      );
      expect(valueNotifier.value, 0);
      expect(streamCalledCount, 0);

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(valueNotifier.value, 0);
      expect(streamCalledCount, 1);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(valueNotifier.value, 1);
      expect(streamCalledCount, 2);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(valueNotifier.value, 2);
      expect(streamCalledCount, 3);
    });

    test('.valueNotifierFuture()', () async {
      final vm = app.viewModels<TestViewModel>();
      var futureCalled = false;
      final valueNotifier = vm.valueNotifierFuture<int>(
        initialData: 0,
        future: Future<int>.delayed(const Duration(milliseconds: 100), () {
          futureCalled = true;
          return 42;
        }),
      );

      expect(valueNotifier.value, 0);
      expect(futureCalled, isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(valueNotifier.value, 42);
      expect(futureCalled, isTrue);
    });

    test('.valueNotifierTransform()', () async {
      final vm = app.viewModels<TestViewModel>();
      final source = ValueNotifier<int>(0);
      int transformer(int v) => v * 2;
      final valueNotifier =
          vm.valueNotifierTransform(source: source, transformer: transformer);
      expect(valueNotifier.value, 0);
      source.value = 1;
      expect(valueNotifier.value, 2);
      source.value = 2;
      expect(valueNotifier.value, 4);

      app.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
      expect(vm.isCallCleared, isTrue);

      await Future.delayed(Duration.zero);

      source.value = 3;
      expect(valueNotifier.value, 4,
          reason: 'after cleared, valueNotifier should not notify listener');
      expect(source.value, 3);
    });

    test('.valueNotifierMerge()', () {
      final vm = app.viewModels<TestViewModel>();
      final source = ValueNotifier<int>(0);
      final source2 = ValueNotifier<int>(0);
      int merger(int a, int b) => a + b;
      final valueNotifier = vm.valueNotifierMerge(
          source1: source, source2: source2, merge: merger);
      expect(valueNotifier.value, 0);
      source.value = 1;
      expect(valueNotifier.value, 1);
      source2.value = 2;
      expect(valueNotifier.value, 3);
      source.value = 3;
      expect(valueNotifier.value, 5);
      source2.value = 4;
      expect(valueNotifier.value, 7);

      app.lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.destroy);
      expect(vm.isCallCleared, isTrue);
      source.value = 5;
      expect(valueNotifier.value, 7,
          reason: 'after cleared, valueNotifier should not notify listener');
      expect(source.value, 5);
      expect(source2.value, 4);
    });

    test('.valueNotifierMerge3()', () {
      final vm = app.viewModels<TestViewModel>();
      final source = ValueNotifier<int>(0);
      final source2 = ValueNotifier<int>(0);
      final source3 = ValueNotifier<int>(0);
      int combiner(int a, int b, int c) => a + b + c;
      final valueNotifier = vm.valueNotifierMerge3(
        source1: source,
        source2: source2,
        source3: source3,
        merge: combiner,
      );
      expect(valueNotifier.value, 0);
      source.value = 1;
      expect(valueNotifier.value, 1);
      source2.value = 2;
      expect(valueNotifier.value, 3);
      source3.value = 3;
      expect(valueNotifier.value, 6);
      source.value = 4;
      expect(valueNotifier.value, 9);
      source2.value = 5;
      expect(valueNotifier.value, 12);
      source3.value = 6;
      expect(valueNotifier.value, 15);
    });

    test('.valueNotifierMerge4()', () {
      final vm = app.viewModels<TestViewModel>();
      final source = ValueNotifier<int>(0);
      final source2 = ValueNotifier<int>(0);
      final source3 = ValueNotifier<int>(0);
      final source4 = ValueNotifier<int>(0);
      int combiner(int a, int b, int c, int d) => a + b + c + d;
      final valueNotifier = vm.valueNotifierMerge4(
        source1: source,
        source2: source2,
        source3: source3,
        source4: source4,
        merge: combiner,
      );
      expect(valueNotifier.value, 0);
      source.value = 1;
      expect(valueNotifier.value, 1);
      source2.value = 2;
      expect(valueNotifier.value, 3);
      source3.value = 3;
      expect(valueNotifier.value, 6);
      source4.value = 4;
      expect(valueNotifier.value, 10);
      source.value = 5;
      expect(valueNotifier.value, 14);
      source2.value = 6;
      expect(valueNotifier.value, 18);
      source3.value = 7;
      expect(valueNotifier.value, 22);
      source4.value = 8;
      expect(valueNotifier.value, 26);
    });

    test('.valueNotifierMerge5()', () {
      final vm = app.viewModels<TestViewModel>();
      final source = ValueNotifier<int>(0);
      final source2 = ValueNotifier<int>(0);
      final source3 = ValueNotifier<int>(0);
      final source4 = ValueNotifier<int>(0);
      final source5 = ValueNotifier<int>(0);
      int combiner(int a, int b, int c, int d, int e) => a + b + c + d + e;
      final valueNotifier = vm.valueNotifierMerge5(
        source1: source,
        source2: source2,
        source3: source3,
        source4: source4,
        source5: source5,
        merge: combiner,
      );
      expect(valueNotifier.value, 0);
      source.value = 1;
      expect(valueNotifier.value, 1);
      source2.value = 2;
      expect(valueNotifier.value, 3);
      source3.value = 3;
      expect(valueNotifier.value, 6);
      source4.value = 4;
      expect(valueNotifier.value, 10);
      source5.value = 5;
      expect(valueNotifier.value, 15);
      source.value = 6;
      expect(valueNotifier.value, 20);
      source2.value = 7;
      expect(valueNotifier.value, 25);
      source3.value = 8;
      expect(valueNotifier.value, 30);
      source4.value = 9;
      expect(valueNotifier.value, 35);
      source5.value = 10;
      expect(valueNotifier.value, 40);
    });

    test('.valueNotifierMerge6()', () {
      final vm = app.viewModels<TestViewModel>();
      final source = ValueNotifier<int>(0);
      final source2 = ValueNotifier<int>(0);
      final source3 = ValueNotifier<int>(0);
      final source4 = ValueNotifier<int>(0);
      final source5 = ValueNotifier<int>(0);
      final source6 = ValueNotifier<int>(0);
      int combiner(int a, int b, int c, int d, int e, int f) =>
          a + b + c + d + e + f;
      final valueNotifier = vm.valueNotifierMerge6(
        source1: source,
        source2: source2,
        source3: source3,
        source4: source4,
        source5: source5,
        source6: source6,
        merge: combiner,
      );
      expect(valueNotifier.value, 0);
      source.value = 1;
      expect(valueNotifier.value, 1);
      source2.value = 2;
      expect(valueNotifier.value, 3);
      source3.value = 3;
      expect(valueNotifier.value, 6);
      source4.value = 4;
      expect(valueNotifier.value, 10);
      source5.value = 5;
      expect(valueNotifier.value, 15);
      source6.value = 6;
      expect(valueNotifier.value, 21);
      source.value = 7;
      expect(valueNotifier.value, 27);
      source2.value = 8;
      expect(valueNotifier.value, 33);
      source3.value = 9;
      expect(valueNotifier.value, 39);
      source4.value = 10;
      expect(valueNotifier.value, 45);
      source5.value = 11;
      expect(valueNotifier.value, 51);
      source6.value = 12;
      expect(valueNotifier.value, 57);
    });

    test('.valueNotifierMerge7()', () {
      final vm = app.viewModels<TestViewModel>();
      final source = ValueNotifier<int>(0);
      final source2 = ValueNotifier<int>(0);
      final source3 = ValueNotifier<int>(0);
      final source4 = ValueNotifier<int>(0);
      final source5 = ValueNotifier<int>(0);
      final source6 = ValueNotifier<int>(0);
      final source7 = ValueNotifier<int>(0);
      int combiner(int a, int b, int c, int d, int e, int f, int g) =>
          a + b + c + d + e + f + g;
      final valueNotifier = vm.valueNotifierMerge7(
        source1: source,
        source2: source2,
        source3: source3,
        source4: source4,
        source5: source5,
        source6: source6,
        source7: source7,
        merge: combiner,
      );
      expect(valueNotifier.value, 0);
      source.value = 1;
      expect(valueNotifier.value, 1);
      source2.value = 2;
      expect(valueNotifier.value, 3);
      source3.value = 3;
      expect(valueNotifier.value, 6);
      source4.value = 4;
      expect(valueNotifier.value, 10);
      source5.value = 5;
      expect(valueNotifier.value, 15);
      source6.value = 6;
      expect(valueNotifier.value, 21);
      source7.value = 7;
      expect(valueNotifier.value, 28);
      source.value = 8;
      expect(valueNotifier.value, 35);
      source2.value = 9;
      expect(valueNotifier.value, 42);
      source3.value = 10;
      expect(valueNotifier.value, 49);
      source4.value = 11;
      expect(valueNotifier.value, 56);
      source5.value = 12;
      expect(valueNotifier.value, 63);
      source6.value = 13;
      expect(valueNotifier.value, 70);
      source7.value = 14;
      expect(valueNotifier.value, 77);
    });

    test('.valueNotifierMerge8()', () {
      final vm = app.viewModels<TestViewModel>();
      final source = ValueNotifier<int>(0);
      final source2 = ValueNotifier<int>(0);
      final source3 = ValueNotifier<int>(0);
      final source4 = ValueNotifier<int>(0);
      final source5 = ValueNotifier<int>(0);
      final source6 = ValueNotifier<int>(0);
      final source7 = ValueNotifier<int>(0);
      final source8 = ValueNotifier<int>(0);
      int combiner(int a, int b, int c, int d, int e, int f, int g, int h) =>
          a + b + c + d + e + f + g + h;
      final valueNotifier = vm.valueNotifierMerge8(
        source1: source,
        source2: source2,
        source3: source3,
        source4: source4,
        source5: source5,
        source6: source6,
        source7: source7,
        source8: source8,
        merge: combiner,
      );
      expect(valueNotifier.value, 0);
      source.value = 1;
      expect(valueNotifier.value, 1);
      source2.value = 2;
      expect(valueNotifier.value, 3);
      source3.value = 3;
      expect(valueNotifier.value, 6);
      source4.value = 4;
      expect(valueNotifier.value, 10);
      source5.value = 5;
      expect(valueNotifier.value, 15);
      source6.value = 6;
      expect(valueNotifier.value, 21);
      source7.value = 7;
      expect(valueNotifier.value, 28);
      source8.value = 8;
      expect(valueNotifier.value, 36);
      source.value = 9;
      expect(valueNotifier.value, 44);
      source2.value = 10;
      expect(valueNotifier.value, 52);
      source3.value = 11;
      expect(valueNotifier.value, 60);
      source4.value = 12;
      expect(valueNotifier.value, 68);
      source5.value = 13;
      expect(valueNotifier.value, 76);
      source6.value = 14;
      expect(valueNotifier.value, 84);
      source7.value = 15;
      expect(valueNotifier.value, 92);
      source8.value = 16;
      expect(valueNotifier.value, 100);
    });

    test('.valueNotifierMerge9()', () {
      final vm = app.viewModels<TestViewModel>();
      final source = ValueNotifier<int>(0);
      final source2 = ValueNotifier<int>(0);
      final source3 = ValueNotifier<int>(0);
      final source4 = ValueNotifier<int>(0);
      final source5 = ValueNotifier<int>(0);
      final source6 = ValueNotifier<int>(0);
      final source7 = ValueNotifier<int>(0);
      final source8 = ValueNotifier<int>(0);
      final source9 = ValueNotifier<int>(0);
      int combiner(
              int a, int b, int c, int d, int e, int f, int g, int h, int i) =>
          a + b + c + d + e + f + g + h + i;
      final valueNotifier = vm.valueNotifierMerge9(
        source1: source,
        source2: source2,
        source3: source3,
        source4: source4,
        source5: source5,
        source6: source6,
        source7: source7,
        source8: source8,
        source9: source9,
        merge: combiner,
      );
      expect(valueNotifier.value, 0);
      source.value = 1;
      expect(valueNotifier.value, 1);
      source2.value = 2;
      expect(valueNotifier.value, 3);
      source3.value = 3;
      expect(valueNotifier.value, 6);
      source4.value = 4;
      expect(valueNotifier.value, 10);
      source5.value = 5;
      expect(valueNotifier.value, 15);
      source6.value = 6;
      expect(valueNotifier.value, 21);
      source7.value = 7;
      expect(valueNotifier.value, 28);
      source8.value = 8;
      expect(valueNotifier.value, 36);
      source9.value = 9;
      expect(valueNotifier.value, 45);
      source.value = 10;
      expect(valueNotifier.value, 54);
      source2.value = 11;
      expect(valueNotifier.value, 63);
      source3.value = 12;
      expect(valueNotifier.value, 72);
      source4.value = 13;
      expect(valueNotifier.value, 81);
      source5.value = 14;
      expect(valueNotifier.value, 90);
      source6.value = 15;
      expect(valueNotifier.value, 99);
      source7.value = 16;
      expect(valueNotifier.value, 108);
      source8.value = 17;
      expect(valueNotifier.value, 117);
      source9.value = 18;
      expect(valueNotifier.value, 126);
    });
  });
}
