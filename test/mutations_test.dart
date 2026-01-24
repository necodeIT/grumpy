// irrelevant for testing purposes
// ignore_for_file: missing_override_of_must_be_overridden
import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:grumpy/grumpy.dart';
import 'package:test/test.dart';

void main() {
  final di = GetIt.instance;
  late _TestTelemetry telemetry;
  late _TestAnalytics analytics;
  late _MutationRepo repo;

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // this is not production code; it's just for test logging
    // ignore: avoid_print
    print(record);
  });

  setUp(() async {
    await di.reset();
    telemetry = _TestTelemetry();
    analytics = _TestAnalytics();
    di.registerSingleton<TelemetryService>(telemetry);
    di.registerSingleton<AnalyticsService>(analytics);
    repo = _MutationRepo();
  });

  tearDown(() async {
    await repo.free();
    await di.reset();
  });
  group('OptimisticPolicy', () {
    test('invokes provided callbacks', () {
      final policy = OptimisticPolicy<int>(
        optimisticValue: (value) => value + 1,
        shouldRevert: (error) => error != null,
      );

      expect(policy.optimisticValue(1), 2);
      expect(policy.shouldRevert(Exception()), isTrue);
      expect(policy.shouldRevert(null), isFalse);
    });

    test('alwaysRevert factory reverts for any error', () {
      final policy = OptimisticPolicy<int>.alwaysRevert(
        optimisticValue: (value) => value * 2,
      );

      expect(policy.optimisticValue(2), 4);
      expect(policy.shouldRevert(Exception()), isTrue);
      expect(policy.shouldRevert(null), isTrue);
    });

    test('neverRevert factory keeps optimistic value', () {
      final policy = OptimisticPolicy<int>.neverRevert(
        optimisticValue: (value) => value - 1,
      );

      expect(policy.optimisticValue(5), 4);
      expect(policy.shouldRevert(Exception()), isFalse);
      expect(policy.shouldRevert(null), isFalse);
    });
  });

  group('RetryPolicy', () {
    test('creates policy with delay and maxAttempts', () {
      const policy = RetryPolicy(delay: Duration(seconds: 1), maxAttempts: 3);

      expect(policy.delay, const Duration(seconds: 1));
      expect(policy.maxAttempts, 3);
    });

    test('throws when maxAttempts is not greater than zero', () {
      expect(
        () => RetryPolicy(delay: Duration.zero, maxAttempts: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('provides a no retry constant', () {
      expect(RetryPolicy.noRetry.delay, Duration.zero);
      expect(RetryPolicy.noRetry.maxAttempts, 1);
    });
  });

  group('MutationMixins', () {
    test('throws when hooks are not installed', () async {
      final uninitialized = _UninitializedMutationRepo()..data(1);

      expect(
        () => uninitialized.mutate('increment', (value) => value + 1),
        throwsA(isA<StateError>()),
      );

      expect(
        () => uninitialized.action('noop', () {}),
        throwsA(isA<StateError>()),
      );

      await uninitialized.free();
    });

    test('mutate updates state and records telemetry/analytics', () async {
      repo.data(1);

      final result = await repo.mutate(
        'increment',
        (current) => current + 1,
        attributes: {'source': 'test'},
      );

      expect(result, 2);
      expect(repo.state.requireData, 2);
      expect(telemetry.runSpanNames, containsAll(['increment', 'try_0']));
      expect(analytics.events, contains('mutation_increment'));
      expect(
        analytics.eventProperties['mutation_increment']?['source'],
        'test',
      );
    });

    test('action runs without initial data', () async {
      expect(repo.state.hasData, isFalse);
      await repo.action(
        'simpleAction',
        () async => repo.data(42),
        attributes: {'actionType': 'test'},
      );

      expect(repo.state.hasData, isTrue);
      expect(telemetry.runSpanNames, contains('simpleAction'));
      expect(analytics.events, contains('action_simpleAction'));
      expect(
        analytics.eventProperties['action_simpleAction']?['actionType'],
        'test',
      );
    });

    test('mutation retries and reverts optimistic update on failure', () async {
      repo.data(5);
      var callCount = 0;

      final policy = OptimisticPolicy<RepoState<int>>.alwaysRevert(
        optimisticValue: (snapshot) => RepoState.data(snapshot.requireData + 1),
      );

      final result = await repo.mutate(
        'sometimesFail',
        (current) {
          callCount++;
          throw StateError('fail');
        },
        optimisticPolicy: policy,
        retryPolicy: const RetryPolicy(delay: Duration.zero, maxAttempts: 2),
      );

      expect(result, isNull);
      expect(callCount, 2);
      expect(repo.state.requireData, 5); // reverted to snapshot
      expect(telemetry.runSpanNames.where((n) => n.startsWith('try_')), [
        'try_0',
        'try_1',
      ]);
    });

    test('mutiations run sequentially using latest state', () async {
      repo.data(2);

      final first = await repo.mutate('increment', (value) => value + 1);
      final second = await repo.mutate('double', (value) => value * 2);

      expect(first, 3);
      expect(second, 6);
      expect(repo.state.requireData, 6);
      expect(
        analytics.events,
        containsAll(['mutation_increment', 'mutation_double']),
      );
      expect(
        telemetry.runSpanNames.where((n) => n == 'try_0').length,
        greaterThanOrEqualTo(2),
      );
      expect(telemetry.runSpanNames, containsAll(['increment', 'double']));
    });

    test(
      'allows later mutations to proceed after an earlier failure',
      () async {
        repo.data(4);

        final failed = await repo.mutate(
          'failThenContinue',
          (_) => throw StateError('nope'),
          optimisticPolicy: OptimisticPolicy<RepoState<int>>.alwaysRevert(
            optimisticValue: (state) => RepoState.data(state.requireData + 10),
          ),
        );

        final succeeded = await repo.mutate('addThree', (value) => value + 3);

        expect(failed, isNull);
        expect(succeeded, 7);
        expect(repo.state.requireData, 7);
        expect(
          analytics.events,
          containsAll(['mutation_failThenContinue', 'mutation_addThree']),
        );
      },
    );

    test(
      'does not roll back newer state when an older optimistic mutation fails',
      () async {
        repo.data(10);
        final results = <String>[];

        final slowFail = repo
            .mutate(
              'slowFail',
              (_) async {
                await Future<void>.delayed(const Duration(milliseconds: 30));
                throw StateError('fail');
              },
              optimisticPolicy: OptimisticPolicy<RepoState<int>>.alwaysRevert(
                optimisticValue: (state) =>
                    RepoState.data(state.requireData + 1),
              ),
            )
            .then((value) => results.add('fail:$value'));

        final fastSuccess = repo
            .mutate('fastSuccess', (value) => value + 5)
            .then((value) => results.add('success:$value'));

        await Future.wait([slowFail, fastSuccess]);

        expect(repo.state.requireData, 16);
        expect(results, containsAll(['fail:null', 'success:16']));
      },
    );

    test('concurrent mutations settle in completion order', () async {
      repo.data(5);

      Future<int?> addOne() => repo.mutate('addOne', (value) async {
        await Future<void>.delayed(const Duration(milliseconds: 25));
        return value + 1;
      });

      Future<int?> addTwo() => repo.mutate('addTwo', (value) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return value + 2;
      });

      final results = await Future.wait([addOne(), addTwo()]);

      expect(results, [6, 7]);
      expect(repo.state.requireData, 6); // last-completing mutation writes last
      expect(
        analytics.events,
        containsAll(['mutation_addOne', 'mutation_addTwo']),
      );
      expect(telemetry.runSpanNames, containsAll(['addOne', 'addTwo']));
    });

    test('applies optimistic update immediately', () async {
      repo.data(3);
      final completer = Completer<void>();

      final mutationFuture = repo.mutate(
        'optimisticIncrement',
        (value) async {
          await completer.future;
          return value + 1;
        },
        optimisticPolicy: OptimisticPolicy<RepoState<int>>.alwaysRevert(
          optimisticValue: (state) => RepoState.data(state.requireData + 1),
        ),
      );

      // optimistic value should be visible before mutation finishes
      await Future<void>.microtask(() {});
      expect(repo.state.requireData, 4);

      completer.complete();
      final result = await mutationFuture;

      expect(result, 4);
      expect(repo.state.requireData, 4);
      expect(analytics.events, contains('mutation_optimisticIncrement'));
    });
  });
}

class _MutationRepo extends Repo<int>
    with
        RepoLifecycleMixin<int>,
        RepoLifecycleHooksMixin<int>,
        TelemetryMixin,
        MutationMixins<int> {
  _MutationRepo() {
    installMutationHooks();
  }

  @override
  Future<void> activate() async {}

  @override
  Future<void> deactivate() async {}

  @override
  Future<void> dependenciesChanged() async {}

  @override
  Future<void> initialize() async {
    await super.initialize();
  }

  @override
  Future<void> free() async {
    await super.free();
  }

  @override
  String get logTag => '_MutationRepo';
}

// for testing uninitialized repo behavior
// ignore: missing_required_constructor_call
class _UninitializedMutationRepo extends Repo<int>
    with
        RepoLifecycleMixin<int>,
        RepoLifecycleHooksMixin<int>,
        TelemetryMixin,
        MutationMixins<int> {
  @override
  Future<void> activate() async {}

  @override
  Future<void> deactivate() async {}

  @override
  Future<void> dependenciesChanged() async {}

  @override
  Future<void> initialize() async {
    await super.initialize();
  }

  @override
  Future<void> free() async {
    await super.free();
  }

  @override
  String get logTag => '_UninitializedMutationRepo';
}

class _TestTelemetry extends TelemetryService {
  final List<String> runSpanNames = [];
  final Map<String, Map<String, dynamic>?> spanAttributes = {};

  @override
  Future<void> recordEvent(
    String name, {
    Map<String, dynamic>? attributes,
  }) async {}

  @override
  Future<void> recordException(
    Object error, [
    StackTrace? stackTrace,
    Map<String, dynamic>? attributes,
  ]) async {}

  @override
  Future<T> runSpan<T>(
    String name,
    FutureOr<T> Function() callback, {
    Map<String, dynamic>? attributes,
  }) async {
    runSpanNames.add(name);
    spanAttributes[name] = attributes;
    return await callback();
  }

  @override
  void addSpanAttribute(String key, String value) {}

  @override
  Future<void> free() async {}
  @override
  String get logTag => '_TestTelemetry';
}

class _TestAnalytics extends AnalyticsService {
  final List<String> events = [];
  final Map<String, Map<String, dynamic>?> eventProperties = {};

  @override
  Future<void> trackEvent(
    String name, {
    Map<String, dynamic>? properties,
  }) async {
    events.add(name);
    eventProperties[name] = properties;
  }

  @override
  Future<void> identifyUser(
    String userId, {
    Map<String, dynamic>? traits,
  }) async {}

  @override
  Future<void> recordNavigation(
    String from,
    String to, {
    Map<String, dynamic>? properties,
  }) async {}

  @override
  Future<void> recordPageView(
    String pageName, {
    Map<String, dynamic>? properties,
  }) async {}

  @override
  Future<void> groupUser(
    String groupId, {
    Map<String, dynamic>? traits,
  }) async {}

  @override
  Future<void> free() async {}
  @override
  String get logTag => '_TestAnalytics';
}
