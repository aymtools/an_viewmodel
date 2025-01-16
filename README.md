A package for managing ViewModel that depends on anlifecycle. Similar to Androidx ViewModel.

## Usage

#### 1.1 Prepare the lifecycle environment.

```dart

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use LifecycleApp to wrap the default App
    return LifecycleApp(
      child: MaterialApp(
        title: 'ViewModel Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        navigatorObservers: [
          //Use LifecycleNavigatorObserver.hookMode() to register routing event changes
          LifecycleNavigatorObserver.hookMode(),
        ],
        home: const MyHomePage(title: 'ViewModel Home Page'),
      ),
    );
  }
}
```

The current usage of PageView and TabBarViewPageView should be replaced with LifecyclePageView and
LifecycleTabBarView. Alternatively, you can wrap the items with LifecyclePageViewItem. You can refer
to [anlifecycle](https://pub.dev/packages/anlifecycle) for guidance.

#### 1.2 Use viewModels<VM> To inject or get the currently existing ViewModel

```dart


class ViewModelHome with ViewModel {
  late final ValueNotifier<int> counter = valueNotifier(0);

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
    final viewModel = context.viewModels<ViewModelHome>();

    // 也可使用 当前提供的构建工厂
    // final viewModel = context.viewModels(factory: ViewModelHome.new);

    // 从路由页来缓存 ViewModel
    // final viewModel = context.viewModelsByRoute<ViewModelHome>();
    //
    // 从App 全局来缓存 ViewModel
    // final  viewModel = context.viewModelsByApp<ViewModelHome>();

    // 当还有引用时 下次获取依然是同一个 当没有任何引用的时候 会执行清理vm
    // final viewModel = context.viewModelsByRef<ViewModelHome>();

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
              builder: (_, __) =>
                  Text(
                    '${viewModel.counter.value}',
                    style: Theme
                        .of(context)
                        .textTheme
                        .headlineMedium,
                  ),
            ),
          ],
        ),
      ),
      floatingActionButton: const HomeFloatingButton(),
    );
  }
}

/// Simulate child widgets.
class HomeFloatingButton extends StatefulWidget {
  const HomeFloatingButton({super.key});

  @override
  State<HomeFloatingButton> createState() => _HomeFloatingButtonState();
}

class _HomeFloatingButtonState extends State<HomeFloatingButton> {
  //Retrieve the ViewModel in the current environment.
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

```

## Additional information

See [anlifecycle](https://pub.dev/packages/anlifecycle)

See [cancelable](https://pub.dev/packages/cancellable)

See [an_lifecycle_cancellable](https://pub.dev/packages/an_lifecycle_cancellable)
