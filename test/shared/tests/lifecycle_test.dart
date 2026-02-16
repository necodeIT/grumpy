// irrelevant for testing purposes
// ignore_for_file: missing_override_of_must_be_overridden

import 'package:logging/logging.dart';
import 'package:test/test.dart';
import '../harness/lifecycle_test_harness.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // this is not production code; it's just for test logging
    // ignore: avoid_print
    print(record);
  });

  group('LifecycleMixin', () {
    test('tracks lifecycle invocations and prevents double dispose', () async {
      final target = LifecycleTarget();

      await target.activate();
      await target.deactivate();
      await target.dependenciesChanged();
      await target.free();

      expect(target.initializeCalls, 1);
      expect(target.activateCalls, 1);
      expect(target.deactivateCalls, 1);
      expect(target.dependenciesChangedCalls, 1);
      expect(target.disposed, isTrue);

      expect(() => target.free(), throwsA(isA<StateError>()));
    });
  });

  group('LifecycleHooksMixin', () {
    test('runs registered hooks for each lifecycle stage', () async {
      final lifecycle = HookedLifecycle();
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
      await lifecycle.free();

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
      final lifecycle = HookedLifecycle();
      final calls = <String>[];

      lifecycle.onActivate(() async {
        await Future<void>.delayed(Duration.zero);
        calls.add('asyncActivate');
      });
      lifecycle.onDisposed(() => calls.add('dispose'));

      await lifecycle.activate();
      await lifecycle.free();

      expect(calls, ['asyncActivate', 'dispose']);
      expect(() => lifecycle.free(), throwsA(isA<StateError>()));
    });
  });

  group('RepoLifecycleHooksMixin', () {
    test('fires hooks when repo emits states', () async {
      final repo = HookedRepo();
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

      await repo.free();
    });
  });
}
