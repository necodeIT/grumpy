// irrelevant for testing purposes
// ignore_for_file: missing_override_of_must_be_overridden

import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import '../harness/module_test_harness.dart';

void main() {
  final di = GetIt.instance;

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // this is not production code; it's just for test logging
    // ignore: avoid_print
    print(record);
  });

  setUp(() async {
    await di.reset();
    di.registerSingleton<TestConfig>(const TestConfig('cfg'));
  });

  tearDown(() async {
    await di.reset();
  });

  test('Module binds dependencies', () async {
    final importModule = ImportModule();
    final module = TestModule(importModule);

    await module.initialize();
    await module.activate();

    expect(importModule.initializeCount, 1);
    expect(importModule.disposeCount, 0);

    final externalA = di.get<ExternalDependency>();
    final externalB = di.get<ExternalDependency>();
    expect(externalA.config, same(di.get<TestConfig>()));
    expect(externalB.config, same(di.get<TestConfig>()));
    expect(externalA, same(externalB));

    final service = di.get<FakeService>();
    expect(service.config, same(di.get<TestConfig>()));

    final singletonService = di.get<SingletonFakeService>();
    expect(singletonService.config, same(di.get<TestConfig>()));

    final datasource = di.get<FakeDatasource>();
    expect(datasource.config, same(di.get<TestConfig>()));

    final singletonDatasource = di.get<SingletonFakeDatasource>();
    expect(singletonDatasource.config, same(di.get<TestConfig>()));

    final repo = await di.getAsync<FakeRepo>();
    expect(repo.config, same(di.get<TestConfig>()));
    expect(repo.initializeCallCount, greaterThanOrEqualTo(1));
    expect(repo.initializeHookRan, isTrue);
    expect(repo.activateCount, 1);

    await module.free();
  });

  group('Injectables', () {
    test('marked as factory return a new instance per resolution', () async {
      final module = TestModule(ImportModule());
      await module.initialize();

      final serviceA = di.get<FakeService>();
      final serviceB = di.get<FakeService>();
      expect(serviceA, isNot(same(serviceB)));

      final datasourceA = di.get<FakeDatasource>();
      final datasourceB = di.get<FakeDatasource>();
      expect(datasourceA, isNot(same(datasourceB)));

      await module.free();
    });

    test(
      'marked as singelton return the same instance per resolution',
      () async {
        final module = TestModule(ImportModule());
        await module.initialize();

        final serviceA = di.get<SingletonFakeService>();
        final serviceB = di.get<SingletonFakeService>();
        expect(serviceA, same(serviceB));

        final datasourceA = di.get<SingletonFakeDatasource>();
        final datasourceB = di.get<SingletonFakeDatasource>();
        expect(datasourceA, same(datasourceB));

        await module.free();
      },
    );
  });

  test('Classes are not available after disposing module', () async {
    final importModule = ImportModule();
    final module = TestModule(importModule);
    await module.initialize();
    final repo = await di.getAsync<FakeRepo>();
    await module.free();

    expect(importModule.disposeCount, 1);
    expect(repo.deactivateCount, greaterThanOrEqualTo(0));
    expect(repo.disposed, isTrue);
    expect(di.isRegistered<ExternalDependency>(), isFalse);
    expect(di.isRegistered<FakeService>(), isFalse);
    expect(di.isRegistered<SingletonFakeService>(), isFalse);
    expect(di.isRegistered<FakeDatasource>(), isFalse);
    expect(di.isRegistered<SingletonFakeDatasource>(), isFalse);
    expect(di.isRegistered<FakeRepo>(), isFalse);
    expect(di.get<TestConfig>(), isA<TestConfig>());
  });

  test('Repos are deactivated and reactivated without cold start', () async {
    final module = TestModule(ImportModule());
    await module.initialize();
    await module.activate();
    final repo = await di.getAsync<FakeRepo>();

    expect(repo.initializeCallCount, 1);
    expect(repo.activateCount, 1);
    expect(repo.deactivateCount, 0);

    await module.deactivate();
    expect(repo.deactivateCount, 1);
    expect(repo.disposed, isFalse);

    await module.activate();
    expect(repo.initializeCallCount, 1);
    expect(repo.activateCount, 2);

    await module.free();
    expect(repo.disposed, isTrue);
  });

  group('Lifecycle-managed injectables', () {
    test(
      'singleton lifecycle service is initialized once across warm cycles',
      () async {
        final module = LifecycleModule();
        await module.initialize();

        expect(() => di.get<LifecycleService>(), throwsA(isA<StateError>()));

        await module.activate();
        final service = di.get<LifecycleService>();

        expect(service.initializeCalls, 1);
        expect(service.activateCalls, 1);

        await module.deactivate();
        expect(service.deactivateCalls, 1);

        await module.activate();
        expect(service.initializeCalls, 1);
        expect(service.activateCalls, 2);

        await module.dependenciesChanged();
        expect(service.dependenciesChangedCalls, 1);

        await module.free();
      },
    );

    test(
      'singleton lifecycle datasource is managed by module lifecycle',
      () async {
        final module = LifecycleModule();
        await module.initialize();
        await module.activate();

        final datasource = di.get<LifecycleDatasource>();
        expect(datasource.initializeCalls, 1);
        expect(datasource.activateCalls, 1);

        await module.deactivate();
        expect(datasource.deactivateCalls, 1);

        await module.free();
      },
    );

    test('lifecycle factory service registration throws', () async {
      final module = InvalidLifecycleServiceModule();
      expect(() => module.initialize(), throwsA(isA<StateError>()));
    });

    test('lifecycle factory datasource registration throws', () async {
      final module = InvalidLifecycleDatasourceModule();
      expect(() => module.initialize(), throwsA(isA<StateError>()));
    });
  });
}
