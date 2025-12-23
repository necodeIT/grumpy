import 'package:modular_foundation/modular_foundation.dart';
import 'package:test/test.dart';

void main() {
  group('LifecycleMixin', () {
    test('tracks lifecycle invocations and prevents double dispose', () async {
      final target = _LifecycleTarget();

      await target.initialize();
      await target.activate();
      await target.deactivate();
      await target.dependenciesChanged();
      await target.dispose();

      expect(target.initializeCalls, 1);
      expect(target.activateCalls, 1);
      expect(target.deactivateCalls, 1);
      expect(target.dependenciesChangedCalls, 1);
      expect(target.disposed, isTrue);

      expect(() => target.dispose(), throwsA(isA<StateError>()));
    });
  });

  group('LifecycleHooksMixin', () {
    test('runs registered hooks for each lifecycle stage', () async {
      final lifecycle = _HookedLifecycle();
      final calls = <String>[];

      lifecycle.onInitialize(() => calls.add('initialize'));
      lifecycle.onActivate(() => calls.add('activate'));
      lifecycle.onDeactivate(() => calls.add('deactivate'));
      lifecycle.onDependenciesChanged(() => calls.add('dependenciesChanged'));
      lifecycle.onDisposed(() => calls.add('dispose'));

      await lifecycle.initialize();
      await lifecycle.activate();
      await lifecycle.deactivate();
      await lifecycle.dependenciesChanged();
      await lifecycle.dispose();

      expect(calls, [
        'initialize',
        'activate',
        'deactivate',
        'dependenciesChanged',
        'dispose',
      ]);
      expect(lifecycle.disposed, isTrue);
    });

    test('supports async hooks and clears on dispose', () async {
      final lifecycle = _HookedLifecycle();
      final calls = <String>[];

      lifecycle.onActivate(() async {
        await Future<void>.delayed(Duration.zero);
        calls.add('asyncActivate');
      });
      lifecycle.onDisposed(() => calls.add('dispose'));

      await lifecycle.activate();
      await lifecycle.dispose();

      expect(calls, ['asyncActivate', 'dispose']);
      expect(() => lifecycle.dispose(), throwsA(isA<StateError>()));
    });
  });

  group('RepoLifecycleHooksMixin', () {
    test('fires hooks when repo emits states', () async {
      final repo = _HookedRepo();
      final dataCalls = <int>[];
      final errorCalls = <Object>[];
      var loadingCalls = 0;

      repo.onData(dataCalls.add);
      repo.onError((error, _) => errorCalls.add(error));
      repo.onLoading(() => loadingCalls++);

      repo.data(1);
      repo.loading();
      final exception = Exception('boom');
      repo.error(exception);

      expect(dataCalls, [1]);
      expect(loadingCalls, 1);
      expect(errorCalls.single, same(exception));

      await repo.dispose();
    });
  });
}

class _LifecycleTarget with Disposable, LifecycleMixin {
  int initializeCalls = 0;
  int activateCalls = 0;
  int deactivateCalls = 0;
  int dependenciesChangedCalls = 0;
  bool disposed = false;

  @override
  Future<void> activate() async {
    activateCalls++;
  }

  @override
  Future<void> deactivate() async {
    deactivateCalls++;
  }

  @override
  Future<void> dependenciesChanged() async {
    dependenciesChangedCalls++;
  }

  @override
  Future<void> initialize() async {
    initializeCalls++;
  }

  @override
  Future<void> dispose() async {
    await super.dispose();
    disposed = true;
  }
}

class _HookedLifecycle
    with Disposable, LogMixin, LifecycleMixin, LifecycleHooksMixin {
  bool disposed = false;

  @override
  void log(String message, [Object? error, StackTrace? stackTrace]) {
    // No-op logger for tests.
  }

  @override
  Future<void> dispose() async {
    await super.dispose();
    disposed = true;
  }
}

class _HookedRepo extends Repo<int>
    with RepoLifecycleMixin<int>, RepoLifecycleHooksMixin<int> {
  @override
  Future<void> activate() async {}

  @override
  Future<void> deactivate() async {}

  @override
  Future<void> dependenciesChanged() async {}

  @override
  Future<void> dispose() async {
    await super.dispose();
  }

  @override
  Future<void> initialize() async {
    await super.initialize();
  }
}
