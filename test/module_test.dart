import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:grumpy/grumpy.dart';
import 'package:test/test.dart';

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
    di.registerSingleton<_TestConfig>(const _TestConfig('cfg'));
  });

  tearDown(() async {
    await di.reset();
  });

  test('Module binds dependencies', () async {
    final importModule = _ImportModule();
    final module = _TestModule(importModule);

    await module.ready;

    expect(importModule.initializeCount, 1);
    expect(importModule.disposeCount, 0);

    final externalA = di.get<_ExternalDependency>();
    final externalB = di.get<_ExternalDependency>();
    expect(externalA.config, same(di.get<_TestConfig>()));
    expect(externalB.config, same(di.get<_TestConfig>()));
    expect(externalA, same(externalB));

    final service = di.get<_FakeService>();
    expect(service.config, same(di.get<_TestConfig>()));

    final datasource = di.get<_FakeDatasource>();
    expect(datasource.config, same(di.get<_TestConfig>()));

    final repo = await di.getAsync<_FakeRepo>();
    expect(repo.config, same(di.get<_TestConfig>()));
    expect(repo.initializeCallCount, greaterThanOrEqualTo(2));
    expect(repo.initializeHookRan, isTrue);
    expect(repo.activateCount, 1);

    await module.free();
  });

  test('Classes are not available after disposing module', () async {
    final importModule = _ImportModule();
    final module = _TestModule(importModule);
    await module.ready;
    final repo = await di.getAsync<_FakeRepo>();
    await module.free();

    expect(importModule.disposeCount, 1);
    expect(repo.deactivateCount, greaterThanOrEqualTo(0));
    expect(repo.disposed, isTrue);
    expect(di.isRegistered<_ExternalDependency>(), isFalse);
    expect(di.isRegistered<_FakeService>(), isFalse);
    expect(di.isRegistered<_FakeDatasource>(), isFalse);
    expect(di.isRegistered<_FakeRepo>(), isFalse);
    expect(di.get<_TestConfig>(), isA<_TestConfig>());
  });
}

class _TestModule extends Module<int, _TestConfig> {
  // initilaize is in an enclosure
  // ignore: call_initialize_in_constructor
  _TestModule(this._importModule) {
    ready = Future.sync(() => initialize());
  }

  late final Future<void> ready;

  final _ImportModule _importModule;

  @override
  List<Module<int, _TestConfig>> get imports => [_importModule];

  @override
  void bindExternalDeps(Bind<Object, _TestConfig> bind) {
    bind((config, resolver) => _ExternalDependency(config));
  }

  @override
  void bindServices(Bind<Service, _TestConfig> bind) {
    bind((config, resolver) => _FakeService(config));
  }

  @override
  void bindDatasources(Bind<Datasource, _TestConfig> bind) {
    bind((config, resolver) => _FakeDatasource(config));
  }

  @override
  void bindRepos(Bind<Repo, _TestConfig> bind) {
    bind((config, resolver) => _FakeRepo(config));
  }

  @override
  Future<void> activate() async {
    super.activate();
  }

  @override
  Future<void> deactivate() async {
    super.deactivate();
  }

  @override
  Future<void> dependenciesChanged() async {}

  @override
  List<Route<int, _TestConfig>> get routes => [];
}

class _ImportModule extends Module<int, _TestConfig> {
  int initializeCount = 0;
  int disposeCount = 0;

  @override
  Future<void> initialize() async {
    initializeCount++;
    await super.initialize();
  }

  @override
  Future<void> free() async {
    disposeCount++;
    await super.free();
  }

  @override
  Future<void> activate() async {
    super.activate();
  }

  @override
  Future<void> deactivate() async {
    super.deactivate();
  }

  @override
  Future<void> dependenciesChanged() async {}

  @override
  List<Route<int, _TestConfig>> get routes => [];
}

class _ExternalDependency extends Object {
  const _ExternalDependency(this.config);

  final _TestConfig config;
}

class _FakeService extends Service {
  _FakeService(this.config);

  final _TestConfig config;

  @override
  Future<void> free() async {}
}

class _FakeDatasource extends Datasource {
  _FakeDatasource(this.config);

  final _TestConfig config;

  @override
  Future<void> free() async {}
}

class _FakeRepo extends Repo<int> {
  _FakeRepo(this.config) {
    onInitialize(() => initializeHookRan = true);
    onActivate(() => activateCount++);
    onDeactivate(() => deactivateCount++);
    onDisposed(() => disposed = true);

    initialize();
  }

  final _TestConfig config;

  int initializeCallCount = 0;
  int activateCount = 0;
  int deactivateCount = 0;
  bool initializeHookRan = false;
  bool disposed = false;

  @override
  Future<void> initialize() async {
    initializeCallCount++;
    await super.initialize();
  }

  @override
  Future<void> activate() async {
    await super.activate();
  }

  @override
  Future<void> deactivate() async {
    await super.deactivate();
  }

  @override
  Future<void> dependenciesChanged() async {}

  @override
  Future<void> free() async {
    await super.free();
  }
}

class _TestConfig {
  const _TestConfig(this.id);

  final String id;
}
