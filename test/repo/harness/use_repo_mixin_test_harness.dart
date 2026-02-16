import 'dart:async';
import 'package:grumpy/grumpy.dart';

class UseRepoConsumer
    with
        Disposable,
        LogMixin,
        LifecycleMixin,
        LifecycleHooksMixin,
        UseRepoMixin<String, String, String> {
  UseRepoConsumer() {
    installUseRepoHooks();
    onDependenciesChanged(() => dependenciesChangedCalls++);
    initialize();
  }

  int dependenciesChangedCalls = 0;
  int errorCalls = 0;
  Object? lastError;

  @override
  FutureOr<String> onDependenciesReady() async {
    final (count, _) = await useRepo<int, IntRepo>();
    final (label, _) = await useRepo<String, StringRepo>();
    return '$count-$label';
  }

  @override
  FutureOr<String> onDependencyError(Object error, StackTrace? _) {
    errorCalls++;
    lastError = error;
    return 'error:${error.toString()}';
  }

  @override
  String onDependenciesLoading() {
    return 'loading';
  }

  @override
  String get logTag => 'UseRepoConsumer';
}

// for testing uninitialized usage
// ignore: missing_required_constructor_call
class UninitializedConsumer
    with
        Disposable,
        LogMixin,
        LifecycleMixin,
        LifecycleHooksMixin,
        UseRepoMixin<void, void, void> {
  @override
  FutureOr<void> onDependenciesReady() {}

  @override
  FutureOr<void> onDependencyError(Object _, StackTrace? _) {}

  @override
  void onDependenciesLoading() {}
  @override
  String get logTag => 'UninitializedConsumer';
}

class IntRepo extends Repo<int> {
  void setData(int value) => data(value);
  @override
  String get logTag => 'IntRepo';
}

class DeferredCombinedRepo extends Repo<String>
    with UseRepoMixin, DeferredRepoMixin<String> {
  DeferredCombinedRepo() {
    installUseRepoHooks();
  }

  @override
  FutureOr<String> build() async {
    final (count, _) = await useRepo<int, IntRepo>();
    final (label, _) = await useRepo<String, StringRepo>();
    return '$count-$label';
  }

  @override
  String get logTag => 'DeferredCombinedRepo';
}

class StringRepo extends Repo<String> {
  void setData(String value) => data(value);
  void setError(Object error, [StackTrace? stackTrace]) =>
      super.error(error, stackTrace);
  @override
  String get logTag => 'StringRepo';
}
