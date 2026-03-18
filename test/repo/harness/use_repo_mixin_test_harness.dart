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
  FutureOr<String> onDependenciesReady(UseHooks use) async {
    final (count, _) = await use.repo<int, IntRepo>();
    final (label, _) = await use.repo<String, StringRepo>();
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

class SlowSnapshotUseRepoConsumer
    with
        Disposable,
        LogMixin,
        LifecycleMixin,
        LifecycleHooksMixin,
        UseRepoMixin<String, String, String> {
  SlowSnapshotUseRepoConsumer({this.delay = const Duration(milliseconds: 30)}) {
    installUseRepoHooks();
    initialize();
  }

  final Duration delay;
  int readyCalls = 0;
  String? lastSnapshot;
  final Completer<void> firstSnapshotCaptured = Completer<void>();

  @override
  FutureOr<String> onDependenciesReady(UseHooks use) async {
    readyCalls++;
    final (count, _) = await use.repo<int, IntRepo>();
    final (label, _) = await use.repo<String, StringRepo>();
    final snapshot = '$count-$label';
    lastSnapshot = snapshot;
    if (!firstSnapshotCaptured.isCompleted) {
      firstSnapshotCaptured.complete();
    }
    await Future<void>.delayed(delay);
    return snapshot;
  }

  @override
  FutureOr<String> onDependencyError(Object error, StackTrace? _) =>
      'error:${error.toString()}';

  @override
  String onDependenciesLoading() => 'loading';

  @override
  String get logTag => 'SlowSnapshotUseRepoConsumer';
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
  FutureOr<void> onDependenciesReady(UseHooks use) {}

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
  FutureOr<String> build(UseHooks use) async {
    final (count, _) = await use.repo<int, IntRepo>();
    final (label, _) = await use.repo<String, StringRepo>();
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
