import 'dart:async';
import 'package:grumpy/grumpy.dart';

class TestModule extends Module<int, TestConfig> {
  TestModule(this._importModule);

  final ImportModule _importModule;

  @override
  List<Module<int, TestConfig>> get imports => [_importModule];

  @override
  void bindExternalDeps(Bind<Object, TestConfig> bind) {
    bind((config, resolver) => ExternalDependency(config));
  }

  @override
  void bindServices(Bind<Service, TestConfig> bind) {
    bind((config, resolver) => FakeService(config));
    bind((config, resolver) => SingletonFakeService(config));
  }

  @override
  void bindDatasources(Bind<Datasource, TestConfig> bind) {
    bind((config, resolver) => FakeDatasource(config));
    bind((config, resolver) => SingletonFakeDatasource(config));
  }

  @override
  void bindRepos(Bind<Repo, TestConfig> bind) {
    bind((config, resolver) => FakeRepo(config));
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
  List<Route<int, TestConfig>> get routes => [];
  @override
  String get logTag => 'TestModule';
}

class ImportModule extends Module<int, TestConfig> {
  int initializeCount = 0;
  int disposeCount = 0;

  @override
  Future<void> initialize() async {
    initializeCount++;
    await super.initialize();
  }

  @override
  Future<void> destroy() async {
    disposeCount++;
    await super.destroy();
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
  List<Route<int, TestConfig>> get routes => [];
  @override
  String get logTag => 'ImportModule';
}

class ExternalDependency extends Object {
  const ExternalDependency(this.config);

  final TestConfig config;
}

class FakeService extends Service {
  FakeService(this.config);

  final TestConfig config;

  @override
  Future<void> destroy() async {}

  @override
  String get logTag => 'FakeService';
}

class SingletonFakeService extends Service {
  SingletonFakeService(this.config);

  final TestConfig config;

  @override
  bool get singelton => true;

  @override
  Future<void> destroy() async {}

  @override
  String get logTag => 'SingletonFakeService';
}

class FakeDatasource extends Datasource {
  FakeDatasource(this.config);

  final TestConfig config;

  @override
  Future<void> destroy() async {}

  @override
  String get logTag => 'FakeDatasource';
}

class SingletonFakeDatasource extends Datasource {
  SingletonFakeDatasource(this.config);

  final TestConfig config;

  @override
  bool get singelton => true;

  @override
  Future<void> destroy() async {}

  @override
  String get logTag => 'SingletonFakeDatasource';
}

class FakeRepo extends Repo<int> {
  FakeRepo(this.config) {
    onInitialize(() => initializeHookRan = true);
    onActivate(() => activateCount++);
    onDeactivate(() => deactivateCount++);
    onDisposed(() => disposed = true);
  }

  final TestConfig config;

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
  Future<void> destroy() async {
    await super.destroy();
  }

  @override
  String get logTag => 'FakeRepo';
}

class TestConfig {
  const TestConfig(this.id);

  final String id;
}

class LifecycleModule extends Module<int, TestConfig> {
  @override
  void bindServices(Bind<Service, TestConfig> bind) {
    bind((cfg, resolve) => LifecycleService());
  }

  @override
  void bindDatasources(Bind<Datasource, TestConfig> bind) {
    bind((cfg, resolve) => LifecycleDatasource());
  }

  @override
  List<Route<int, TestConfig>> get routes => const [];

  @override
  String get logTag => 'LifecycleModule';
}

class InvalidLifecycleServiceModule extends Module<int, TestConfig> {
  @override
  void bindServices(Bind<Service, TestConfig> bind) {
    bind((cfg, resolve) => FactoryLifecycleService());
  }

  @override
  List<Route<int, TestConfig>> get routes => const [];

  @override
  String get logTag => 'InvalidLifecycleServiceModule';
}

class InvalidLifecycleDatasourceModule extends Module<int, TestConfig> {
  @override
  void bindDatasources(Bind<Datasource, TestConfig> bind) {
    bind((cfg, resolve) => FactoryLifecycleDatasource());
  }

  @override
  List<Route<int, TestConfig>> get routes => const [];

  @override
  String get logTag => 'InvalidLifecycleDatasourceModule';
}

class LifecycleService extends Service with LifecycleMixin {
  int initializeCalls = 0;
  int activateCalls = 0;
  int deactivateCalls = 0;
  int dependenciesChangedCalls = 0;

  @override
  bool get singelton => true;

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
  // Lifecycle test double: this intentionally skips super.free() to avoid
  // disposal side effects that are irrelevant to the assertion scope.
  // ignore: must_call_super
  Future<void> destroy() async {}

  @override
  String get logTag => 'LifecycleService';
}

class LifecycleDatasource extends Datasource with LifecycleMixin {
  int initializeCalls = 0;
  int activateCalls = 0;
  int deactivateCalls = 0;

  @override
  bool get singelton => true;

  @override
  Future<void> activate() async {
    activateCalls++;
  }

  @override
  Future<void> deactivate() async {
    deactivateCalls++;
  }

  @override
  Future<void> dependenciesChanged() async {}

  @override
  Future<void> initialize() async {
    initializeCalls++;
  }

  @override
  // Lifecycle test double: this intentionally skips super.free() to avoid
  // disposal side effects that are irrelevant to the assertion scope.
  // ignore: must_call_super
  Future<void> destroy() async {}

  @override
  String get logTag => 'LifecycleDatasource';
}

class FactoryLifecycleService extends Service with LifecycleMixin {
  @override
  bool get singelton => false;

  @override
  Future<void> activate() async {}

  @override
  Future<void> deactivate() async {}

  @override
  Future<void> dependenciesChanged() async {}

  @override
  Future<void> initialize() async {}

  @override
  // Lifecycle test double: this intentionally skips super.free() to validate
  // registration-time lifecycle constraints in isolation.
  // ignore: must_call_super
  Future<void> destroy() async {}

  @override
  String get logTag => 'FactoryLifecycleService';
}

class FactoryLifecycleDatasource extends Datasource with LifecycleMixin {
  @override
  bool get singelton => false;

  @override
  Future<void> activate() async {}

  @override
  Future<void> deactivate() async {}

  @override
  Future<void> dependenciesChanged() async {}

  @override
  Future<void> initialize() async {}

  @override
  // Lifecycle test double: this intentionally skips super.free() to validate
  // registration-time lifecycle constraints in isolation.
  // ignore: must_call_super
  Future<void> destroy() async {}

  @override
  String get logTag => 'FactoryLifecycleDatasource';
}

class TrackingLifecycleService extends Service with LifecycleMixin {
  int initializeCalls = 0;
  int activateCalls = 0;
  int deactivateCalls = 0;

  @override
  bool get singelton => true;

  @override
  Future<void> activate() async {
    activateCalls++;
  }

  @override
  Future<void> deactivate() async {
    deactivateCalls++;
  }

  @override
  Future<void> dependenciesChanged() async {}

  @override
  Future<void> initialize() async {
    initializeCalls++;
  }

  @override
  // Lifecycle test double: this intentionally skips super.free() to isolate
  // activation/deactivation behavior.
  // ignore: must_call_super
  Future<void> destroy() async {}

  @override
  String get logTag => 'TrackingLifecycleService';
}

class ThrowingActivateLifecycleService extends Service with LifecycleMixin {
  int activateCalls = 0;

  @override
  bool get singelton => true;

  @override
  Future<void> activate() async {
    activateCalls++;
    throw StateError('synthetic activate failure');
  }

  @override
  Future<void> deactivate() async {}

  @override
  Future<void> dependenciesChanged() async {}

  @override
  Future<void> initialize() async {}

  @override
  // Lifecycle test double: this intentionally skips super.free() to isolate
  // activation failure behavior.
  // ignore: must_call_super
  Future<void> destroy() async {}

  @override
  String get logTag => 'ThrowingActivateLifecycleService';
}

class ActivationFailureModule extends Module<int, TestConfig> {
  @override
  void bindServices(Bind<Service, TestConfig> bind) {
    bind((cfg, resolve) => TrackingLifecycleService());
    bind((cfg, resolve) => ThrowingActivateLifecycleService());
  }

  @override
  List<Route<int, TestConfig>> get routes => const [];

  @override
  String get logTag => 'ActivationFailureModule';
}
