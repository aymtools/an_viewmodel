import 'package:an_viewmodel/an_viewmodel.dart';
import 'package:anlifecycle/anlifecycle.dart';

class TestViewModel with ViewModel {
  bool isCallCleared = false;

  @override
  void onCreate(Lifecycle lifecycle) {
    super.onCreate(lifecycle);
  }

  @override
  void onCleared() {
    isCallCleared = true;
  }
}

class TestRefViewModel with ViewModel {
  bool isCallCleared = false;

  @override
  void onCreate(Lifecycle lifecycle) {
    super.onCreate(lifecycle);
  }

  @override
  void onCleared() {
    isCallCleared = true;
  }
}
