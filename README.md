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

void main() {
  /// 提前声明 GlobalViewModel 的创建方式
  /// 并且存放于 app 全局
  ViewModel.factories
      .addFactory(GlobalViewModel.new, producer: ViewModel.producer.byApp);

  runApp(const MyApp());
}

class GlobalViewModel with ViewModel {
  final int step = 2;
}

class HomeViewModel with ViewModel {
  /// 可自动获取 当前scope 或者更上层scope 中的 ViewModel
  late final GlobalViewModel globalViewModel = viewModels();

  late final ValueNotifier<int> counter = valueNotifier(0);

  int curr = 0;

  /// 停留计时器
  late final _stayedStream = useHostLifecycle(
      block: (lifecycle) =>
          Stream.periodic(const Duration(seconds: 1), (i) => i).bindLifecycle(
              lifecycle,
              repeatLastOnStateAtLeast: true,
              state: LifecycleState.resumed)).map((_) => curr++).repeatLatest();

  // 当前页面的停留时间
  late final ValueNotifier<int> stayed =
  valueNotifierStream(stream: _stayedStream, initialData: 0);

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
    final viewModel = context.viewModels(factory: HomeViewModel.new);

    // 如果之前已经提供过 factory 或者已经存在 ViewModel 的实例 可以直接使用
    // final viewModel = context.viewModels<HomeViewModel>();

    // 从路由页来缓存 ViewModel
    // final viewModel = context.viewModelsByRoute<HomeViewModel>();
    //
    // 从App 全局来缓存 ViewModel
    // final  viewModel = context.viewModelsByApp<HomeViewModel>();

    // 当还有引用时 下次获取依然是同一个 当没有任何引用的时候 会执行清理vm
    // final viewModel = context.viewModelsByRef<HomeViewModel>();

    /// 可以配合 LifecycleEffect 用来触发vm的一些事件
    // context.withLifecycleEffect(
    //   launchOnFirstStart: (l) {
    //     print('launchOnFirstStart');
    //     vm.xxxx();
    //   },
    //   repeatOnResumed: (l){
    //     print('repeatOnResumed');
    //     vm.xxxx();
    //   }
    // );

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[

            ValueListenableBuilder(
              valueListenable: viewModel.stayed,
              builder: (context, value, _) =>
                  Text(
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
              builder: (context, value, _) =>
                  Text(
                    '$value',
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

/// 模拟子控件中使用
class HomeFloatingButton extends StatelessWidget {
  const HomeFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.viewModels<HomeViewModel>();
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
