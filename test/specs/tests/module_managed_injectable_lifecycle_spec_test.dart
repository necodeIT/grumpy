import 'package:get_it/get_it.dart';
import 'package:test/test.dart';
import '../harness/module_managed_injectable_lifecycle_harness.dart';

void main() {
  final di = GetIt.instance;

  setUp(() async {
    await di.reset();
    di.registerSingleton<Cfg>(const Cfg());
  });

  tearDown(() async {
    await di.reset();
  });

  group('Spec: module_managed_injectable_lifecycle', () {
    test('activation order is managed injectables then repos', () async {
      final events = <String>[];
      final module = HostModule(
        events: events,
        import: ImportedModule(events: events),
      );
      try {
        await module.initialize();
        await module.activate();

        final serviceActivate = events.indexOf('service.activate');
        final repoActivate = events.indexOf('repo.activate');

        expect(
          serviceActivate >= 0,
          isTrue,
          reason:
              'Spec: module_managed_injectable_lifecycle §6.3 requires managed injectables to activate.',
        );
        expect(
          repoActivate > serviceActivate,
          isTrue,
          reason:
              'Spec: module_managed_injectable_lifecycle §6.3 requires repos to activate after managed injectables.',
        );
      } finally {
        await module.destroy();
      }
    });

    test('deactivation order is repos then managed injectables', () async {
      final events = <String>[];
      final module = HostModule(
        events: events,
        import: ImportedModule(events: events),
      );
      try {
        await module.initialize();
        await module.activate();
        events.clear();

        await module.deactivate();

        final repoDeactivate = events.indexOf('repo.deactivate');
        final serviceDeactivate = events.indexOf('service.deactivate');
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
          serviceDeactivate >= 0,
          isTrue,
          reason:
              'Spec: module_managed_injectable_lifecycle §6.3 requires managed injectables to deactivate after repos.',
        );
      } finally {
        await module.destroy();
      }
    });

    test(
      'dependenciesChanged is delivered to active injectables before repos',
      () async {
        final events = <String>[];
        final module = HostModule(
          events: events,
          import: ImportedModule(events: events),
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
          await module.destroy();
        }
      },
    );

    test(
      'lifecycle-managed injectable cannot be resolved before activation',
      () async {
        final module = HostModule(
          events: <String>[],
          import: ImportedModule(events: <String>[]),
        );
        try {
          await module.initialize();

          expect(
            () => di.get<LifecycleService>(),
            throwsA(isA<StateError>()),
            reason:
                'Spec: module_managed_injectable_lifecycle §6.1.1 enforces readiness only after module activation completes.',
          );
        } finally {
          await module.destroy();
        }
      },
    );

    test('activate bubbles managed injectable lifecycle failures', () async {
      final module = FailureHostModule();
      try {
        await module.initialize();

        expect(
          () => module.activate(),
          throwsA(isA<StateError>()),
          reason:
              'Spec: module_managed_injectable_lifecycle §10 requires async lifecycle failures to fail fast and bubble.',
        );
      } finally {
        await module.destroy();
      }
    });
  });
}
