import 'package:an_lifecycle_cancellable/an_lifecycle_cancellable.dart';
import 'package:an_viewmodel/an_viewmodel.dart';
import 'package:anlifecycle/anlifecycle.dart';
import 'package:flutter/material.dart';

void main() {
  /// 提前声明 ViewModelHome的创建方式
  ViewModelProvider.addDefFactory2(ViewModelHome.new);
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

class ViewModelHome with ViewModel {
  final ValueNotifier<int> counter = ValueNotifier<int>(0);

  ViewModelHome(Lifecycle lifecycle) {
    counter.bindLifecycle(lifecycle);
  }

  void incrementCounter() {
    counter.value++;
  }
}

class MyHomePage extends StatelessWidget {
  final String title;

  const MyHomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    // 获取当前环境下的ViewModel
    final ViewModelHome viewModel = context.viewModels();

    // 也可使用 当前提供的构建工厂
    // final ViewModelHome viewModel =
    //     context.viewModels(factory2: ViewModelHome.new);

    // 从路由页来缓存 ViewModel
    // final ViewModelHome viewModel1 = context.viewModelsByRoute();

    // 从App 全局来缓存 ViewModel
    // final ViewModelHome viewModel1 = context.viewModelsByApp();

    // 当还有引用时 下次获取依然是同一个 当没有任何引用的时候 会执行清理vm
    // final ViewModelHome viewModel1 = context.viewModelsByRef();

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
  late final vm = viewModelsOfState<ViewModelHome>();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: vm.incrementCounter,
      tooltip: 'Increment',
      child: const Icon(Icons.add),
    );
  }
}
