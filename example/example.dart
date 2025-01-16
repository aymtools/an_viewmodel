import 'package:an_viewmodel/an_viewmodel.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:flutter/material.dart';

void main() {
  /// 提前声明 ViewModelHome的创建方式
  ViewModelProvider.addDefFactory2(HomeViewModel.new);
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
        home: const MyHomePage(title: 'ViewModel Demo Home Page'),
      ),
    );
  }
}

class GlobalViewModel with ViewModel {
  final int step = 2;
}

class HomeViewModel with ViewModel {
  final GlobalViewModel globalViewModel;

  late final ValueNotifier<int> counter = valueNotifier(0);

  // 通过传入的Lifecycle 获取全局的 GlobalViewModel
  HomeViewModel(Lifecycle lifecycle)
      : globalViewModel =
            lifecycle.viewModelsByApp(factory: GlobalViewModel.new);

  void incrementCounter() {
    // 使用全局配置的步进
    counter.value = counter.value + globalViewModel.step;
  }
}

class MyHomePage extends StatelessWidget {
  final String title;

  const MyHomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    // 获取当前环境下的ViewModel
    final viewModel = context.viewModels<HomeViewModel>();

    // 也可使用 当前提供的构建工厂
    // final viewModel = context.viewModels(factory2: HomeViewModel.new);

    // 从路由页来缓存 ViewModel
    // final viewModel = context.viewModelsByRoute<HomeViewModel>();
    //
    // 从App 全局来缓存 ViewModel
    // final  viewModel = context.viewModelsByApp<HomeViewModel>();

    // 当还有引用时 下次获取依然是同一个 当没有任何引用的时候 会执行清理vm
    // final viewModel = context.viewModelsByRef<HomeViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            AnimatedBuilder(
              animation: viewModel.counter,
              builder: (_, __) => Text(
                '${viewModel.counter.value}',
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
