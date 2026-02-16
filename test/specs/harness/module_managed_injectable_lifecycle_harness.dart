import 'package:grumpy/grumpy.dart';

class HostModule extends Module<int, Cfg> {
  HostModule({required this.events, required this.import});

  final List<String> events;
  final ImportedModule import;

  @override
  List<Module<int, Cfg>> get imports => <Module<int, Cfg>>[import];

  @override
  void bindServices(Bind<Service, Cfg> bind) {
    bind((cfg, resolve) => LifecycleService(events));
  }

  @override
  void bindRepos(Bind<Repo, Cfg> bind) {
    bind((cfg, resolve) => LifecycleRepo(events));
  }

  @override
  List<Route<int, Cfg>> get routes => const [];

  @override
  String get logTag => 'HostModule';
}

class FailureHostModule extends Module<int, Cfg> {
  @override
  void bindServices(Bind<Service, Cfg> bind) {
    bind((cfg, resolve) => FailingLifecycleService());
  }

  @override
  List<Route<int, Cfg>> get routes => const [];

  @override
  String get logTag => 'FailureHostModule';
}

class ImportedModule extends Module<int, Cfg> {
  ImportedModule({required this.events});

  final List<String> events;

  @override
  Future<void> activate() async {
    events.add('import.activate');
    await super.activate();
  }

  @override
  Future<void> deactivate() async {
    events.add('import.deactivate');
    await super.deactivate();
  }

  @override
  List<Route<int, Cfg>> get routes => const [];

  @override
  String get logTag => 'ImportedModule';
}

class LifecycleService extends Service with LifecycleMixin {
  LifecycleService(this.events);

  final List<String> events;

  @override
  bool get singelton => true;

  @override
  Future<void> activate() async {
    events.add('service.activate');
  }

  @override
  Future<void> deactivate() async {
    events.add('service.deactivate');
  }

  @override
  Future<void> dependenciesChanged() async {
    events.add('service.dependenciesChanged');
  }

  @override
  Future<void> initialize() async {
    events.add('service.initialize');
  }

  @override
  String get logTag => 'LifecycleService';
}

class FailingLifecycleService extends Service with LifecycleMixin {
  @override
  bool get singelton => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> activate() async {
    throw StateError('activation failed');
  }

  @override
  Future<void> deactivate() async {}

  @override
  Future<void> dependenciesChanged() async {}

  @override
  Future<void> free() async {
    super.free();
  }

  @override
  String get logTag => 'FailingLifecycleService';
}

class LifecycleRepo extends Repo<int> {
  LifecycleRepo(this.events) {
    onActivate(() => events.add('repo.activate'));
    onDeactivate(() => events.add('repo.deactivate'));
    onDependenciesChanged(() => events.add('repo.dependenciesChanged'));
  }

  final List<String> events;

  @override
  String get logTag => 'LifecycleRepo';
}

class Cfg {
  const Cfg();
}
