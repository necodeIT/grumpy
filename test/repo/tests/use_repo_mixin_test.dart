// irrelevant for testing purposes
// ignore_for_file: missing_override_of_must_be_overridden
import 'dart:async';

import 'package:get_it/get_it.dart' hide Disposable;
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
        consumer.useRepo<int, IntRepo>(),
        throwsA(isA<StateError>()),
      );

      await consumer.free();
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

      await setup.consumer.free();
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

      await setup.consumer.free();
    });

    test(
      'processes latest dependency update after overlapping emissions',
      () async {
        final intRepo = IntRepo();
        final stringRepo = StringRepo();
        di.registerSingletonAsync<IntRepo>(() async => intRepo);
        di.registerSingletonAsync<StringRepo>(() async => stringRepo);

        final consumer = SlowSnapshotUseRepoConsumer();
        addTearDown(() async => consumer.free());
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
  });

  group('DeferredRepoMixin', () {
    test('builds data when dependencies are ready', () async {
      final setup = await setupDeferredRepo();
      addTearDown(() async => setup.repo.free());

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
      addTearDown(() async => setup.repo.free());

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
  });
}
