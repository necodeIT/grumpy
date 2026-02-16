import 'package:get_it/get_it.dart';
import 'package:grumpy/grumpy.dart';
import 'package:test/test.dart';

void main() {
  final di = GetIt.instance;

  setUp(() async {
    await di.reset();
    di.registerSingleton<_Cfg>(const _Cfg());
  });

  tearDown(() async {
    await di.reset();
  });

  group('Spec: module_managed_injectable_lifecycle', () {
    test('activation order is imports then managed injectables then repos', () async {
      final events = <String>[];
      final module = _HostModule(
        events: events,
        import: _ImportedModule(events: events),
      );
      try {
        await module.initialize();
        await module.activate();

        final importedActivate = events.indexOf('import.activate');
        final serviceActivate = events.indexOf('service.activate');
        final repoActivate = events.indexOf('repo.activate');

        expect(
          importedActivate >= 0,
          isTrue,
          reason:
              'Spec: module_managed_injectable_lifecycle §6.3 requires imported modules to activate first.',
        );
        expect(
          serviceActivate > importedActivate,
          isTrue,
          reason:
              'Spec: module_managed_injectable_lifecycle §6.3 requires managed injectables to activate after imports.',
        );
        expect(
          repoActivate > serviceActivate,
          isTrue,
          reason:
              'Spec: module_managed_injectable_lifecycle §6.3 requires repos to activate after managed injectables.',
        );
      } finally {
        await module.free();
      }
    });

    test(
      'deactivation order is repos then managed injectables then imports',
      () async {
        final events = <String>[];
        final module = _HostModule(
          events: events,
          import: _ImportedModule(events: events),
        );
        try {
          await module.initialize();
          await module.activate();
          events.clear();

          await module.deactivate();

          final repoDeactivate = events.indexOf('repo.deactivate');
          final serviceDeactivate = events.indexOf('service.deactivate');
          final importDeactivate = events.indexOf('import.deactivate');

          expect(
            repoDeactivate >= 0,
            isTrue,
            reason:
                'Spec: module_managed_injectable_lifecycle §6.3 requires repos to deactivate first.',
          );
          expect(
            serviceDeactivate > repoDeactivate,
            isTrue,
            reason:
                'Spec: module_managed_injectable_lifecycle §6.3 requires managed injectables to deactivate after repos.',
          );
          expect(
            importDeactivate > serviceDeactivate,
            isTrue,
            reason:
                'Spec: module_managed_injectable_lifecycle §6.3 requires imported modules to deactivate last.',
          );
        } finally {
          await module.free();
        }
      },
    );

    test(
      'dependenciesChanged is delivered to active injectables before repos',
      () async {
        final events = <String>[];
        final module = _HostModule(
          events: events,
          import: _ImportedModule(events: events),
        );
        try {
          await module.initialize();
          await module.activate();
          events.clear();

          await module.dependenciesChanged();

          final serviceIndex = events.indexOf('service.dependenciesChanged');
          final repoIndex = events.indexOf('repo.dependenciesChanged');

          expect(
            serviceIndex >= 0,
            isTrue,
            reason:
                'Spec: module_managed_injectable_lifecycle §6.3 requires dependenciesChanged propagation to active managed injectables.',
          );
          expect(
            repoIndex > serviceIndex,
            isTrue,
            reason:
                'Spec: module_managed_injectable_lifecycle §6.3 defines managed injectable dependency updates before repos.',
          );
        } finally {
          await module.free();
        }
      },
    );

    test(
      'lifecycle-managed injectable cannot be resolved before activation',
      () async {
        final module = _HostModule(
          events: <String>[],
          import: _ImportedModule(events: <String>[]),
        );
        try {
          await module.initialize();

          expect(
            () => di.get<_LifecycleService>(),
            throwsA(isA<StateError>()),
            reason:
                'Spec: module_managed_injectable_lifecycle §6.1.1 enforces readiness only after module activation completes.',
          );
        } finally {
          await module.free();
        }
      },
    );

    test('activate bubbles managed injectable lifecycle failures', () async {
      final module = _FailureHostModule();
      try {
        await module.initialize();

        expect(
          () => module.activate(),
          throwsA(isA<StateError>()),
          reason:
              'Spec: module_managed_injectable_lifecycle §10 requires async lifecycle failures to fail fast and bubble.',
        );
      } finally {
        await module.free();
      }
    });
  });
}

class _HostModule extends Module<int, _Cfg> {
  _HostModule({required this.events, required this.import});

  final List<String> events;
  final _ImportedModule import;

  @override
  List<Module<int, _Cfg>> get imports => <Module<int, _Cfg>>[import];

  @override
  void bindServices(Bind<Service, _Cfg> bind) {
    bind((cfg, resolve) => _LifecycleService(events));
  }

  @override
  void bindRepos(Bind<Repo, _Cfg> bind) {
    bind((cfg, resolve) => _LifecycleRepo(events));
  }

  @override
  List<Route<int, _Cfg>> get routes => const [];

  @override
  String get logTag => '_HostModule';
}

class _FailureHostModule extends Module<int, _Cfg> {
  @override
  void bindServices(Bind<Service, _Cfg> bind) {
    bind((cfg, resolve) => _FailingLifecycleService());
  }

  @override
  List<Route<int, _Cfg>> get routes => const [];

  @override
  String get logTag => '_FailureHostModule';
}

class _ImportedModule extends Module<int, _Cfg> {
  _ImportedModule({required this.events});

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
  List<Route<int, _Cfg>> get routes => const [];

  @override
  String get logTag => '_ImportedModule';
}

class _LifecycleService extends Service with LifecycleMixin {
  _LifecycleService(this.events);

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
  Future<void> free() async {}

  @override
  String get logTag => '_LifecycleService';
}

class _FailingLifecycleService extends Service with LifecycleMixin {
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
  Future<void> free() async {}

  @override
  String get logTag => '_FailingLifecycleService';
}

class _LifecycleRepo extends Repo<int> {
  _LifecycleRepo(this.events) {
    onActivate(() => events.add('repo.activate'));
    onDeactivate(() => events.add('repo.deactivate'));
    onDependenciesChanged(() => events.add('repo.dependenciesChanged'));
  }

  final List<String> events;

  @override
  String get logTag => '_LifecycleRepo';
}

class _Cfg {
  const _Cfg();
}
