import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:an_viewmodel/an_viewmodel.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:flutter/material.dart';

class GlobalViewModel with ViewModel {
  final int step = 2;
}

void main() {
  /// 提前声明 GlobalViewModel 的创建方式
  ViewModelProvider.addDefFactory(GlobalViewModel.new);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LifecycleApp(
      child: MaterialApp(
        title: 'ViewModel Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        navigatorObservers: [
          LifecycleNavigatorObserver.hookMode(),
        ],
        home: const HomeViewModelDemo(title: 'ViewModel Demo Home Page'),
      ),
    );
  }
}

class HomeViewModel with ViewModel {
  final Lifecycle lifecycle;
  final GlobalViewModel globalViewModel;

  late final ValueNotifier<int> counter = valueNotifier(0);

  /// 停留计时器
  late final _stayedStream =
      Stream.periodic(const Duration(seconds: 1), (i) => i)
          .bindLifecycle(lifecycle, repeatLastOnRestart: true)
          .repeatLatest();

  // 当前页面的停留时间
  late final ValueNotifier<int> stayed =
      valueNotifierStream(stream: _stayedStream, initialData: 0);

  // 通过传入的Lifecycle 获取全局的 GlobalViewModel
  HomeViewModel(this.lifecycle) : globalViewModel = lifecycle.viewModelsByApp();

  void incrementCounter() {
    // 使用全局配置的步进
    counter.value = counter.value + globalViewModel.step;
  }
}

class HomeViewModelDemo extends StatelessWidget {
  final String title;

  const HomeViewModelDemo({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    // 使用当前提供的 factory 按需创建 ViewModel
    final viewModel = context.viewModels(factory2: HomeViewModel.new);

    // 如果之前已经提供过 factory 或者已经存在 ViewModel 的实例 可以直接使用
    // final viewModel = context.viewModels<HomeViewModel>();

    // 从路由页来缓存 ViewModel
    // final viewModel = context.viewModelsByRoute<HomeViewModel>();
    //
    // 从App 全局来缓存 ViewModel
    // final  viewModel = context.viewModelsByApp<HomeViewModel>();

    // 当还有引用时 下次获取依然是同一个 当没有任何引用的时候 会执行清理vm
    // final viewModel = context.viewModelsByRef<HomeViewModel>();

    /// 同时使用当前 context 所在的lifecycle和viewmodel对象 来处理生命周期变化
    // final viewModel = context.withLifecycleAndViewModelEffect(
    //   factory2: HomeViewModel.new,
    //   launchOnFirstStart: (lifecycle, vm) {
    //     print('launchOnFirstStart');
    //   },
    //   repeatOnResumed: (lifecycle, vm) {
    //     print('repeatOnResumed');
    //   },
    // );

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            /// 如果你更喜欢使用 Hook  [an_lifecycle_hooks](https://pub.dev/packages/an_lifecycle_hooks)
            ValueListenableBuilder(
              valueListenable: viewModel.stayed,
              builder: (context, value, _) => Text(
                'Stayed on this page for:$value s',
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
            ),
            const Text(
              'You have pushed the button this many times:',
            ),

            ValueListenableBuilder(
              valueListenable: viewModel.counter,
              builder: (context, value, _) => Text(
                '$value',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const HomeFloatingButton(),
    );
  }
}

/// 模拟子控件  可以在 state中直接使用
class HomeFloatingButton extends StatefulWidget {
  const HomeFloatingButton({super.key});

  @override
  State<HomeFloatingButton> createState() => _HomeFloatingButtonState();
}

class _HomeFloatingButtonState extends State<HomeFloatingButton> {
  //获取vm   可以在 state中直接使用
  late final vm = viewModelsOfState<HomeViewModel>();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: vm.incrementCounter,
      tooltip: 'Increment',
      child: const Icon(Icons.add),
    );
  }
}
