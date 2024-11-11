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
  final ValueNotifier<int> counter = ValueNotifier<int>(0);

  ViewModelHome(Lifecycle lifecycle) {
    /// Associate the ValueNotifier with the Lifecycle, and automatically call dispose when the lifecycle ends.
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
    // Retrieve the ViewModel in the current environment.
    final ViewModelHome viewModel =
    context.viewModels(factory2: ViewModelHome.new);

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

See [anlifecycle](https://github.com/aymtools/lifecycle/)

See [cancelable](https://github.com/aymtools/cancelable/)

See [an_lifecycle_cancellable](https://github.com/aymtools/lifecycle_cancellable/)
