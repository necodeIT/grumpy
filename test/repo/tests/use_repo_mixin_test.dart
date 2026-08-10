// irrelevant for testing purposes
// ignore_for_file: missing_override_of_must_be_overridden
import 'dart:async';

import 'package:get_it/get_it.dart' hide Disposable;
import 'package:grumpy/grumpy.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import '../harness/use_repo_mixin_test_harness.dart';

typedef _UseRepoSetup = ({
  IntRepo intRepo,
  StringRepo stringRepo,
  UseRepoConsumer consumer,
});

typedef _DeferredRepoSetup = ({
  IntRepo intRepo,
  StringRepo stringRepo,
  DeferredCombinedRepo repo,
});

void main() {
  final di = GetIt.instance;

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // this is not production code; it's just for test logging
    // ignore: avoid_print
    print(record);
  });

  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  Future<_UseRepoSetup> setupConsumer() async {
    final intRepo = IntRepo();
    final stringRepo = StringRepo();

    di.registerSingletonAsync<IntRepo>(() async => intRepo);
    di.registerSingletonAsync<StringRepo>(() async => stringRepo);

    final consumer = UseRepoConsumer();
    await consumer.initialize();
    await settle();

    return (intRepo: intRepo, stringRepo: stringRepo, consumer: consumer);
  }

  Future<_DeferredRepoSetup> setupDeferredRepo() async {
    final intRepo = IntRepo();
    final stringRepo = StringRepo();

    di.registerSingletonAsync<IntRepo>(() async => intRepo);
    di.registerSingletonAsync<StringRepo>(() async => stringRepo);

    final repo = DeferredCombinedRepo();
    await repo.initialize();
    await settle();

    return (intRepo: intRepo, stringRepo: stringRepo, repo: repo);
  }

  setUp(() async {
    await di.reset();
  });

  tearDown(() async {
    await di.reset();
  });

  group('UseRepoMixin', () {
    test('throws when hooks are not installed', () async {
      final consumer = UninitializedConsumer();

      await expectLater(
        // still is visible for testing
        // ignore: deprecated_member_use_from_same_package
        consumer.useRepo<int, IntRepo>(),
        throwsA(isA<StateError>()),
      );

      await consumer.destroy();
    });

    test(
      'waits for pending runtime work before resolving a missing repo',
      () async {
        final readiness = ControlledDependencyReadiness();
        di.registerSingleton<DependencyReadiness>(readiness);

        final consumer = UseRepoConsumer();
        addTearDown(consumer.destroy);
        await settle();

        expect(readiness.waitCalls, equals(1));
        expect(consumer.errorCalls, isZero);

        final intRepo = IntRepo();
        final stringRepo = StringRepo();
        di.registerSingletonAsync<IntRepo>(() async => intRepo);
        di.registerSingletonAsync<StringRepo>(() async => stringRepo);
        readiness.complete();
        await settle();

        intRepo.setData(3);
        await settle();
        stringRepo.setData('ready');
        await settle();

        final state = consumer.when(
          data: (value) => value,
          error: (value) => value,
          loading: (value) => value,
        );
        expect(state, equals('3-ready'));
        expect(consumer.errorCalls, isZero);
      },
    );

    test(
      'waits for pending runtime work before resolving a registered repo',
      () async {
        final readiness = ControlledDependencyReadiness();
        di.registerSingleton<DependencyReadiness>(readiness);

        final intRepo = IntRepo()..setData(3);
        final stringRepo = StringRepo()..setData('ready');
        di.registerSingletonAsync<IntRepo>(() async => intRepo);
        di.registerSingletonAsync<StringRepo>(() async => stringRepo);

        final consumer = UseRepoConsumer();
        addTearDown(consumer.destroy);
        await settle();

        expect(readiness.waitCalls, equals(1));
        expect(
          consumer.when(
            data: (value) => value,
            error: (value) => value,
            loading: (value) => value,
          ),
          equals('loading'),
        );

        readiness.complete();
        await settle();

        expect(
          consumer.when(
            data: (value) => value,
            error: (value) => value,
            loading: (value) => value,
          ),
          equals('3-ready'),
        );
      },
    );

    test('abandons pending repo resolution when disposed', () async {
      final readiness = ControlledDependencyReadiness();
      di.registerSingleton<DependencyReadiness>(readiness);
      final consumer = UseRepoConsumer();
      await settle();

      expect(readiness.waitCalls, equals(1));
      final baselineChanges = consumer.dependenciesChangedCalls;
      await consumer.destroy();

      di.registerSingletonAsync<IntRepo>(() async => IntRepo());
      readiness.complete();
      await settle();

      expect(consumer.dependenciesChangedCalls, equals(baselineChanges));
      expect(consumer.errorCalls, isZero);
    });

    test('rebuilds data when dependencies become ready', () async {
      final setup = await setupConsumer();

      final baselineChanges = setup.consumer.dependenciesChangedCalls;

      final initialState = setup.consumer.when(
        data: (value) => value,
        error: (value) => value,
        loading: (value) => value,
      );
      expect(initialState, equals('loading'));

      setup.intRepo.setData(1);
      await settle();

      final midState = setup.consumer.when(
        data: (value) => value,
        error: (value) => value,
        loading: (value) => value,
      );
      expect(midState, equals('loading'));
      expect(
        setup.consumer.dependenciesChangedCalls,
        equals(baselineChanges + 1),
      );

      setup.stringRepo.setData('ready');
      await settle();

      final finalState = setup.consumer.when(
        data: (value) => value,
        error: (value) => value,
        loading: (value) => value,
      );
      expect(finalState, equals('1-ready'));
      expect(
        setup.consumer.dependenciesChangedCalls,
        equals(baselineChanges + 2),
      );

      await setup.consumer.destroy();
    });

    test('surfaces dependency errors', () async {
      final setup = await setupConsumer();

      setup.intRepo.setData(1);
      await settle();

      final error = Exception('boom');
      setup.stringRepo.setError(error);
      await settle();

      final state = setup.consumer.when(
        data: (value) => value,
        error: (value) => value,
        loading: (value) => value,
      );

      expect(state, equals('error:${error.toString()}'));
      expect(setup.consumer.lastError, same(error));
      expect(setup.consumer.errorCalls, equals(1));

      await setup.consumer.destroy();
    });

    test(
      'processes latest dependency update after overlapping emissions',
      () async {
        final intRepo = IntRepo();
        final stringRepo = StringRepo();
        di.registerSingletonAsync<IntRepo>(() async => intRepo);
        di.registerSingletonAsync<StringRepo>(() async => stringRepo);

        final consumer = SlowSnapshotUseRepoConsumer();
        addTearDown(() async => consumer.destroy());
        await settle();

        intRepo.setData(0);
        stringRepo.setData('ready');
        await settle();
        await Future<void>.delayed(const Duration(milliseconds: 40));

        intRepo.setData(1);
        await consumer.firstSnapshotCaptured.future;
        intRepo.setData(2);
        await Future<void>.delayed(const Duration(milliseconds: 60));

        final state = consumer.when(
          data: (value) => value,
          error: (value) => value,
          loading: (value) => value,
        );

        expect(state, equals('2-ready'));
        expect(consumer.readyCalls, greaterThanOrEqualTo(3));
      },
    );

    test('does not let initial discovery overwrite a newer rebuild', () async {
      final intRepo = IntRepo()..setData(1);
      di.registerSingletonAsync<IntRepo>(() async => intRepo);

      final consumer = ControlledInitialBuildConsumer();
      addTearDown(consumer.destroy);

      await consumer.firstSnapshotCaptured.future;
      intRepo.setData(2);
      await settle();
      consumer.releaseFirstBuild.complete();
      await settle();

      final state = consumer.when(
        data: (value) => value,
        error: (error) => throw error,
        loading: (_) => fail('Expected dependency data.'),
      );

      expect(state, equals(2));
      expect(consumer.readyCalls, equals(2));
    });

    test(
      'watchExternal returns sync snapshot without waiting for emission',
      () async {
        var listenCount = 0;
        final controller = StreamController<void>(
          onListen: () => listenCount++,
        );
        final snapshot = 'initial';
        final consumer = ExternalSignalConsumer(
          key: Object(),
          changeSignal: controller.stream,
          syncSnapshot: () => snapshot,
        );
        addTearDown(() async {
          await consumer.destroy();
          await controller.close();
        });
        await settle();

        final state = consumer.when(
          data: (value) => value,
          error: (value) => value,
          loading: (value) => value,
        );

        expect(state, equals('initial'));
        expect(listenCount, equals(1));
        expect(consumer.readyCalls, equals(1));
      },
    );

    test(
      'watchExternal rebuilds from latest sync snapshot on signal',
      () async {
        final controller = StreamController<void>.broadcast();
        var snapshot = 'initial';
        final consumer = ExternalSignalConsumer(
          key: Object(),
          changeSignal: controller.stream,
          syncSnapshot: () => snapshot,
        );
        addTearDown(() async {
          await consumer.destroy();
          await controller.close();
        });
        await settle();

        snapshot = 'updated';
        controller.add(null);
        await settle();

        final state = consumer.when(
          data: (value) => value,
          error: (value) => value,
          loading: (value) => value,
        );

        expect(state, equals('updated'));
        expect(consumer.readyCalls, equals(2));
      },
    );

    test('watchExternal reuses subscription for same key and signal', () async {
      var listenCount = 0;
      final controller = StreamController<void>(onListen: () => listenCount++);
      var snapshot = 'initial';
      final consumer = ExternalSignalConsumer(
        key: Object(),
        changeSignal: controller.stream,
        syncSnapshot: () => snapshot,
      );
      addTearDown(() async {
        await consumer.destroy();
        await controller.close();
      });
      await settle();

      snapshot = 'next';
      controller.add(null);
      await settle();

      expect(listenCount, equals(1));
      expect(consumer.readyCalls, equals(2));
    });

    test(
      'watchExternal replaces subscription when signal changes for same key',
      () async {
        var firstListenCount = 0;
        var secondListenCount = 0;
        final firstController = StreamController<void>(
          onListen: () => firstListenCount++,
        );
        final secondController = StreamController<void>(
          onListen: () => secondListenCount++,
        );
        const key = #external;
        var snapshot = 'first';
        final consumer = ExternalSignalConsumer(
          key: key,
          changeSignal: firstController.stream,
          syncSnapshot: () => snapshot,
        );
        addTearDown(() async {
          await consumer.destroy();
          await firstController.close();
          await secondController.close();
        });
        await settle();

        consumer.changeSignal = secondController.stream;
        snapshot = 'second';
        firstController.add(null);
        await settle();

        final stateAfterReplacement = consumer.when(
          data: (value) => value,
          error: (value) => value,
          loading: (value) => value,
        );

        expect(stateAfterReplacement, equals('second'));
        expect(firstListenCount, equals(1));
        expect(secondListenCount, equals(1));

        snapshot = 'stale';
        firstController.add(null);
        await settle();

        final stateAfterOldSignal = consumer.when(
          data: (value) => value,
          error: (value) => value,
          loading: (value) => value,
        );

        expect(stateAfterOldSignal, equals('second'));
        expect(consumer.readyCalls, equals(2));

        snapshot = 'third';
        secondController.add(null);
        await settle();

        final stateAfterNewSignal = consumer.when(
          data: (value) => value,
          error: (value) => value,
          loading: (value) => value,
        );

        expect(stateAfterNewSignal, equals('third'));
        expect(consumer.readyCalls, equals(3));
      },
    );

    test(
      'watchExternal routes sync snapshot errors through onDependencyError',
      () async {
        final controller = StreamController<void>.broadcast();
        var shouldThrow = false;
        final snapshotError = StateError('snapshot failed');
        final consumer = ExternalSignalConsumer(
          key: Object(),
          changeSignal: controller.stream,
          syncSnapshot: () {
            if (shouldThrow) throw snapshotError;
            return 'ready';
          },
        );
        addTearDown(() async {
          await consumer.destroy();
          await controller.close();
        });
        await settle();

        shouldThrow = true;
        controller.add(null);
        await settle();

        final state = consumer.when(
          data: (value) => value,
          error: (value) => value,
          loading: (value) => value,
        );

        expect(state, equals('error:${snapshotError.toString()}'));
        expect(consumer.lastError, same(snapshotError));
        expect(consumer.errorCalls, equals(1));
      },
    );

    test(
      'watchExternal routes change signal errors and recovers on next event',
      () async {
        final controller = StreamController<void>.broadcast();
        var snapshot = 'ready';
        final signalError = Exception('signal failed');
        final consumer = ExternalSignalConsumer(
          key: Object(),
          changeSignal: controller.stream,
          syncSnapshot: () => snapshot,
        );
        addTearDown(() async {
          await consumer.destroy();
          await controller.close();
        });
        await settle();

        controller.addError(signalError);
        await settle();

        final errorState = consumer.when(
          data: (value) => value,
          error: (value) => value,
          loading: (value) => value,
        );

        expect(errorState, equals('error:${signalError.toString()}'));
        expect(consumer.lastError, same(signalError));

        snapshot = 'recovered';
        controller.add(null);
        await settle();

        final recoveredState = consumer.when(
          data: (value) => value,
          error: (value) => value,
          loading: (value) => value,
        );

        expect(recoveredState, equals('recovered'));
        expect(consumer.readyCalls, equals(2));
      },
    );

    test('watchExternal subscriptions are cancelled on dispose', () async {
      final controller = StreamController<void>.broadcast();
      var snapshot = 'initial';
      final consumer = ExternalSignalConsumer(
        key: Object(),
        changeSignal: controller.stream,
        syncSnapshot: () => snapshot,
      );
      await settle();

      final baselineChanges = consumer.dependenciesChangedCalls;
      await consumer.destroy();

      snapshot = 'after-dispose';
      controller.add(null);
      await settle();
      await controller.close();

      expect(consumer.dependenciesChangedCalls, equals(baselineChanges));
    });

    test('payloadStream loads until the first payload is emitted', () async {
      var listenCount = 0;
      final controller = StreamController<String>.broadcast(
        onListen: () => listenCount++,
      );
      final consumer = PayloadStreamConsumer(
        key: Object(),
        sourceKey: 'profile',
        stream: controller.stream,
      );
      addTearDown(() async {
        await consumer.destroy();
        await controller.close();
      });
      await settle();

      final loadingState = consumer.when(
        data: (value) => value,
        error: (value) => value,
        loading: (value) => value,
      );

      expect(loadingState, equals('loading'));
      expect(listenCount, equals(1));
      expect(consumer.streamFactoryCalls, equals(1));

      controller.add('initial');
      await settle();

      final dataState = consumer.when(
        data: (value) => value,
        error: (value) => value,
        loading: (value) => value,
      );

      expect(dataState, equals('initial'));
      expect(consumer.streamFactoryCalls, equals(1));
    });

    test('payloadStream rebuilds from each emitted payload', () async {
      final controller = StreamController<String>.broadcast();
      final consumer = PayloadStreamConsumer(
        key: Object(),
        sourceKey: 'profile',
        stream: controller.stream,
      );
      addTearDown(() async {
        await consumer.destroy();
        await controller.close();
      });
      await settle();

      controller.add('initial');
      await settle();
      controller.add('updated');
      await settle();

      final state = consumer.when(
        data: (value) => value,
        error: (value) => value,
        loading: (value) => value,
      );

      expect(state, equals('updated'));
      expect(consumer.readyCalls, greaterThanOrEqualTo(3));
    });

    test(
      'payloadStream replaces its subscription when sourceKey changes',
      () async {
        var firstCancelCount = 0;
        final firstController = StreamController<String>.broadcast(
          onCancel: () => firstCancelCount++,
        );
        final secondController = StreamController<String>.broadcast();
        final consumer = PayloadStreamConsumer(
          key: 'profile',
          sourceKey: 'first-user',
          stream: firstController.stream,
        );
        addTearDown(() async {
          await consumer.destroy();
          await firstController.close();
          await secondController.close();
        });
        await settle();

        firstController.add('first-profile');
        await settle();
        expect(consumer.streamFactoryCalls, equals(1));

        firstController.addError(Exception('first source failed'));
        await settle();

        consumer
          ..sourceKey = 'second-user'
          ..stream = secondController.stream;
        firstController.addError(Exception('source changed'));
        await settle();

        final loadingState = consumer.when(
          data: (value) => value,
          error: (value) => value,
          loading: (value) => value,
        );
        expect(loadingState, equals('loading'));
        expect(consumer.streamFactoryCalls, equals(2));
        expect(firstCancelCount, equals(1));

        secondController.add('second-profile');
        await settle();

        final dataState = consumer.when(
          data: (value) => value,
          error: (value) => value,
          loading: (value) => value,
        );
        expect(dataState, equals('second-profile'));
        expect(consumer.streamFactoryCalls, equals(2));
      },
    );

    test(
      'payloadStream routes stream errors and recovers on payload',
      () async {
        final controller = StreamController<String>.broadcast();
        final error = Exception('payload failed');
        final consumer = PayloadStreamConsumer(
          key: Object(),
          sourceKey: 'profile',
          stream: controller.stream,
        );
        addTearDown(() async {
          await consumer.destroy();
          await controller.close();
        });
        await settle();

        controller.addError(error);
        await settle();

        final errorState = consumer.when(
          data: (value) => value,
          error: (value) => value,
          loading: (value) => value,
        );

        expect(errorState, equals('error:${error.toString()}'));
        expect(consumer.lastError, same(error));

        controller.add('recovered');
        await settle();

        final recoveredState = consumer.when(
          data: (value) => value,
          error: (value) => value,
          loading: (value) => value,
        );

        expect(recoveredState, equals('recovered'));
      },
    );

    test(
      'payloadStream recreates its subscription when the stream closes',
      () async {
        final firstController = StreamController<String>.broadcast();
        final secondController = StreamController<String>.broadcast();
        final consumer = PayloadStreamConsumer(
          key: Object(),
          sourceKey: 'profile',
          stream: firstController.stream,
        );
        addTearDown(() async {
          await consumer.destroy();
          await firstController.close();
          await secondController.close();
        });
        await settle();

        firstController.add('initial');
        await settle();
        expect(consumer.streamFactoryCalls, equals(1));

        consumer.stream = secondController.stream;
        await firstController.close();
        await settle();

        final loadingState = consumer.when(
          data: (value) => value,
          error: (value) => value,
          loading: (value) => value,
        );
        expect(loadingState, equals('loading'));
        expect(consumer.streamFactoryCalls, equals(2));

        secondController.add('reconnected');
        await settle();

        final dataState = consumer.when(
          data: (value) => value,
          error: (value) => value,
          loading: (value) => value,
        );
        expect(dataState, equals('reconnected'));
        expect(consumer.streamFactoryCalls, equals(2));
      },
    );

    test(
      'payloadStream recreates its subscription after an error closes the stream',
      () async {
        final firstController = StreamController<String>.broadcast();
        final secondController = StreamController<String>.broadcast();
        final consumer = PayloadStreamConsumer(
          key: Object(),
          sourceKey: 'profile',
          stream: firstController.stream,
        );
        addTearDown(() async {
          await consumer.destroy();
          await firstController.close();
          await secondController.close();
        });
        await settle();

        firstController.add('initial');
        await settle();

        consumer.stream = secondController.stream;
        firstController.addError(Exception('connection closed'));
        await firstController.close();
        await settle();

        expect(consumer.streamFactoryCalls, equals(2));
        expect(
          consumer.when(
            data: (value) => value,
            error: (value) => value,
            loading: (value) => value,
          ),
          equals('loading'),
        );

        secondController.add('recovered');
        await settle();

        expect(
          consumer.when(
            data: (value) => value,
            error: (value) => value,
            loading: (value) => value,
          ),
          equals('recovered'),
        );
      },
    );
  });

  group('DeferredRepoMixin', () {
    test(
      'does not wait on the runtime that is initializing the repo itself',
      () async {
        final readiness = ControlledDependencyReadiness();
        di.registerSingleton<DependencyReadiness>(readiness);

        final intRepo = IntRepo()..setData(7);
        final stringRepo = StringRepo()..setData('ready');
        di.registerSingletonAsync<IntRepo>(() async => intRepo);
        di.registerSingletonAsync<StringRepo>(() async => stringRepo);

        final repo = DeferredCombinedRepo();
        addTearDown(repo.destroy);
        await repo.initialize();
        await settle();

        expect(repo.state.hasData, isTrue);
        expect(repo.state.data, equals('7-ready'));
        expect(readiness.waitCalls, isZero);
      },
    );

    test('builds data when dependencies are ready', () async {
      final setup = await setupDeferredRepo();
      addTearDown(() async => setup.repo.destroy());

      expect(setup.repo.state.isLoading, isTrue);

      setup.intRepo.setData(7);
      await settle();

      expect(setup.repo.state.isLoading, isTrue);

      setup.stringRepo.setData('ready');
      await settle();

      expect(setup.repo.state.hasData, isTrue);
      expect(setup.repo.state.data, equals('7-ready'));

      setup.intRepo.setData(8);
      await settle();

      expect(setup.repo.state.data, equals('8-ready'));
    });

    test('propagates dependency errors and recovers', () async {
      final setup = await setupDeferredRepo();
      addTearDown(() async => setup.repo.destroy());

      setup.intRepo.setData(1);
      setup.stringRepo.setData('ok');
      await settle();

      expect(setup.repo.state.data, equals('1-ok'));

      final error = Exception('boom');
      setup.stringRepo.setError(error);
      await settle();

      expect(setup.repo.state.hasError, isTrue);
      expect(setup.repo.state.asError.error, same(error));

      setup.stringRepo.setData('back');
      await settle();

      expect(setup.repo.state.data, equals('1-back'));
    });

    test(
      'rebuilds data from latest external sync snapshot on signal',
      () async {
        final controller = StreamController<void>.broadcast();
        var snapshot = 'initial';
        final repo = ExternalSignalDeferredRepo(
          key: Object(),
          changeSignal: controller.stream,
          syncSnapshot: () => snapshot,
        );
        addTearDown(() async {
          await repo.destroy();
          await controller.close();
        });

        await repo.initialize();
        await settle();

        expect(repo.state.hasData, isTrue);
        expect(repo.state.data, equals('initial'));

        snapshot = 'updated';
        controller.add(null);
        await settle();

        expect(repo.state.hasData, isTrue);
        expect(repo.state.data, equals('updated'));
      },
    );

    test('rebuilds data from latest payload stream value', () async {
      final controller = StreamController<String>.broadcast();
      final repo = PayloadStreamDeferredRepo(
        key: Object(),
        payloads: controller.stream,
      );
      addTearDown(() async {
        await repo.destroy();
        await controller.close();
      });

      await repo.initialize();
      await settle();

      expect(repo.state.isLoading, isTrue);

      controller.add('initial');
      await settle();

      expect(repo.state.hasData, isTrue);
      expect(repo.state.data, equals('initial'));

      controller.add('updated');
      await settle();

      expect(repo.state.hasData, isTrue);
      expect(repo.state.data, equals('updated'));
    });

    test(
      'publishes a payload emitted while dependency discovery is completing',
      () async {
        late final StreamController<String> controller;
        controller = StreamController<String>.broadcast(
          onListen: () => controller.add('initial'),
        );
        final repo = PayloadStreamDeferredRepo(
          key: Object(),
          payloads: controller.stream,
        );
        addTearDown(() async {
          await repo.destroy();
          await controller.close();
        });

        await repo.initialize();
        await settle();

        expect(repo.state.hasData, isTrue);
        expect(repo.state.data, equals('initial'));
      },
    );
  });
}
