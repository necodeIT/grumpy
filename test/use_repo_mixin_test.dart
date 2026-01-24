// irrelevant for testing purposes
// ignore_for_file: missing_override_of_must_be_overridden
import 'dart:async';

import 'package:get_it/get_it.dart' hide Disposable;
import 'package:logging/logging.dart';
import 'package:grumpy/grumpy.dart';
import 'package:test/test.dart';

typedef _UseRepoSetup = ({
  _IntRepo intRepo,
  _StringRepo stringRepo,
  _UseRepoConsumer consumer,
});

typedef _DeferredRepoSetup = ({
  _IntRepo intRepo,
  _StringRepo stringRepo,
  _DeferredCombinedRepo repo,
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
    final intRepo = _IntRepo();
    final stringRepo = _StringRepo();

    di.registerSingletonAsync<_IntRepo>(() async => intRepo);
    di.registerSingletonAsync<_StringRepo>(() async => stringRepo);

    final consumer = _UseRepoConsumer();
    await consumer.initialize();
    await settle();

    return (intRepo: intRepo, stringRepo: stringRepo, consumer: consumer);
  }

  Future<_DeferredRepoSetup> setupDeferredRepo() async {
    final intRepo = _IntRepo();
    final stringRepo = _StringRepo();

    di.registerSingletonAsync<_IntRepo>(() async => intRepo);
    di.registerSingletonAsync<_StringRepo>(() async => stringRepo);

    final repo = _DeferredCombinedRepo();
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
      final consumer = _UninitializedConsumer();

      await expectLater(
        consumer.useRepo<int, _IntRepo>(),
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

class _UseRepoConsumer
    with
        Disposable,
        LogMixin,
        LifecycleMixin,
        LifecycleHooksMixin,
        UseRepoMixin<String, String, String> {
  _UseRepoConsumer() {
    installUseRepoHooks();
    onDependenciesChanged(() => dependenciesChangedCalls++);
    initialize();
  }

  int dependenciesChangedCalls = 0;
  int errorCalls = 0;
  Object? lastError;

  @override
  FutureOr<String> onDependenciesReady() async {
    final (count, _) = await useRepo<int, _IntRepo>();
    final (label, _) = await useRepo<String, _StringRepo>();
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
  String get logTag => '_UseRepoConsumer';
}

// for testing uninitialized usage
// ignore: missing_required_constructor_call
class _UninitializedConsumer
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
  String get logTag => '_UninitializedConsumer';
}

class _IntRepo extends Repo<int> {
  void setData(int value) => data(value);
  @override
  String get logTag => '_IntRepo';
}

class _DeferredCombinedRepo extends Repo<String>
    with UseRepoMixin, DeferredRepoMixin<String> {
  _DeferredCombinedRepo() {
    installUseRepoHooks();
  }

  @override
  FutureOr<String> build() async {
    final (count, _) = await useRepo<int, _IntRepo>();
    final (label, _) = await useRepo<String, _StringRepo>();
    return '$count-$label';
  }

  @override
  String get logTag => '_DeferredCombinedRepo';
}

class _StringRepo extends Repo<String> {
  void setData(String value) => data(value);
  void setError(Object error, [StackTrace? stackTrace]) =>
      super.error(error, stackTrace);
  @override
  String get logTag => '_StringRepo';
}
