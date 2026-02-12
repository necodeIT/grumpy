// irrelevant for testing purposes
// ignore_for_file: missing_override_of_must_be_overridden, must_call_super, unused_element_parameter
import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:grumpy/grumpy.dart';
import 'package:grumpy/src/infra/services/canonical_module_registry_service.dart';
import 'package:test/test.dart';

void main() {
  group('CanonicalModuleRegistryService', () {
    test('canonicalize keeps one instance per runtime type', () {
      final events = <String>[];
      final registry = CanonicalModuleRegistryService<int, _Cfg>();
      final first = _FeatureModule('first', events: events);
      final second = _FeatureModule('second', events: events);

      final canonicalFirst = registry.canonicalize(first);
      final canonicalSecond = registry.canonicalize(second);

      expect(canonicalFirst, same(first));
      expect(canonicalSecond, same(first));
      expect(registry.modulesByType.length, 1);
      expect(registry.getByType(_FeatureModule), same(first));
      expect(registry.dependencyGraph[first], isEmpty);
    });

    test('canonicalize recursively canonicalizes imported modules', () {
      final events = <String>[];
      final registry = CanonicalModuleRegistryService<int, _Cfg>();
      final depA = _DependencyModule('dep-a', events: events);
      final depB = _DependencyModule('dep-b', events: events);
      final featureA = _FeatureModule('feature-a', events: events, deps: [depA]);
      final featureB = _FeatureModule('feature-b', events: events, deps: [depB]);

      final canonicalFeature = registry.canonicalize(featureA);
      registry.canonicalize(featureB);

      final canonicalDep = registry.getByType(_DependencyModule);
      expect(canonicalFeature, same(featureA));
      expect(canonicalDep, same(depA));
      expect(registry.modulesByType.length, 2);
      expect(registry.dependencyGraph[featureA], equals({depA}));
    });

    test('sync activates in dependency order and deactivates in reverse order', () async {
      final events = <String>[];
      final registry = CanonicalModuleRegistryService<int, _Cfg>();
      final dep = _DependencyModule('dep', events: events);
      final feature = _FeatureModule('feature', events: events, deps: [dep]);

      await registry.sync([feature]);
      await registry.sync(const <Module<int, _Cfg>>[]);

      expect(
        events,
        equals([
          'initialize:dep',
          'activate:dep',
          'initialize:feature',
          'activate:feature',
          'deactivate:feature',
          'deactivate:dep',
        ]),
      );
    });

    test('sync is idempotent for already-active module set', () async {
      final events = <String>[];
      final registry = CanonicalModuleRegistryService<int, _Cfg>();
      final dep = _DependencyModule('dep', events: events);
      final feature = _FeatureModule('feature', events: events, deps: [dep]);

      await registry.sync([feature]);
      await registry.sync([feature]);

      expect(dep.initializeCalls, 1);
      expect(dep.activateCalls, 1);
      expect(feature.initializeCalls, 1);
      expect(feature.activateCalls, 1);
      expect(dep.deactivateCalls, 0);
      expect(feature.deactivateCalls, 0);
    });

    test('ensureActive and ensureInactive preserve shared dependencies', () async {
      final events = <String>[];
      final registry = CanonicalModuleRegistryService<int, _Cfg>();
      final shared = _SharedModule('shared', events: events);
      final featureA = _FeatureModule('feature-a', events: events, deps: [shared]);
      final settings = _SettingsModule('settings', events: events, deps: [shared]);

      await registry.ensureActive(featureA);
      await registry.ensureActive(settings);
      await registry.ensureInactive(featureA);

      expect(registry.isActive(settings), isTrue);
      expect(registry.isActive(shared), isTrue);
      expect(registry.isActive(featureA), isFalse);
      expect(shared.deactivateCalls, 0);

      await registry.ensureInactive(settings);

      expect(registry.activeModules, isEmpty);
      expect(shared.deactivateCalls, 1);
    });

    test('isActive resolves aliases via canonical instance', () async {
      final events = <String>[];
      final registry = CanonicalModuleRegistryService<int, _Cfg>();
      final first = _FeatureModule('first', events: events);
      final second = _FeatureModule('second', events: events);

      await registry.ensureActive(first);

      expect(registry.isActive(second), isTrue);
      expect(first.activateCalls, 1);
      expect(second.activateCalls, 0);
    });

    test('resolveDependencies returns transitive canonicalized modules', () {
      final events = <String>[];
      final registry = CanonicalModuleRegistryService<int, _Cfg>();
      final leafA = _LeafModule('leaf-a', events: events);
      final leafB = _LeafModule('leaf-b', events: events);
      final depA = _DependencyModule('dep-a', events: events, deps: [leafA]);
      final depB = _DependencyModule('dep-b', events: events, deps: [leafB]);
      final featureA = _FeatureModule('feature-a', events: events, deps: [depA]);
      final featureB = _FeatureModule('feature-b', events: events, deps: [depB]);

      final resolved = registry.resolveDependencies([featureA, featureB]);

      expect(resolved.length, 3);
      expect(resolved, contains(featureA));
      expect(resolved, contains(depA));
      expect(resolved, contains(leafA));
      expect(registry.getByType(_FeatureModule), same(featureA));
      expect(registry.getByType(_DependencyModule), same(depA));
      expect(registry.getByType(_LeafModule), same(leafA));
    });

    test('sync throws for circular imports', () async {
      final events = <String>[];
      final registry = CanonicalModuleRegistryService<int, _Cfg>();
      final cycleA = _CycleAModule('a', events: events);
      final cycleB = _CycleBModule('b', events: events);
      cycleA.setDeps([cycleB]);
      cycleB.setDeps([cycleA]);

      expect(() => registry.sync([cycleA]), throwsA(isA<StateError>()));
    });

    test('registry recovers after failed sync and can process new work', () async {
      final events = <String>[];
      final registry = CanonicalModuleRegistryService<int, _Cfg>();
      final cycleA = _CycleAModule('a', events: events);
      final cycleB = _CycleBModule('b', events: events);
      cycleA.setDeps([cycleB]);
      cycleB.setDeps([cycleA]);

      expect(() => registry.sync([cycleA]), throwsA(isA<StateError>()));

      final feature = _FeatureModule('feature', events: events);
      await registry.sync([feature]);

      expect(registry.activeModules, equals({feature}));
      expect(feature.initializeCalls, 1);
      expect(feature.activateCalls, 1);
    });

    test('queued ensureActive calls are serialized and keep final union', () async {
      final events = <String>[];
      final registry = CanonicalModuleRegistryService<int, _Cfg>();
      final shared = _SharedModule(
        'shared',
        events: events,
        activateDelay: const Duration(milliseconds: 30),
      );
      final feature = _FeatureModule('feature', events: events, deps: [shared]);
      final settings = _SettingsModule('settings', events: events, deps: [shared]);

      await Future.wait([
        registry.ensureActive(feature),
        registry.ensureActive(settings),
      ]);

      expect(registry.activeModules.length, 3);
      expect(registry.activeModules, contains(shared));
      expect(registry.activeModules, contains(feature));
      expect(registry.activeModules, contains(settings));
      expect(shared.initializeCalls, 1);
      expect(shared.activateCalls, 1);
    });

    test('free deactivates all active modules', () async {
      final events = <String>[];
      final registry = CanonicalModuleRegistryService<int, _Cfg>();
      final dep = _DependencyModule('dep', events: events);
      final feature = _FeatureModule('feature', events: events, deps: [dep]);

      await registry.sync([feature]);
      await registry.free();

      expect(registry.activeModules, isEmpty);
      expect(feature.deactivateCalls, 1);
      expect(dep.deactivateCalls, 1);
    });

    test(
      'sync adopts already-mounted modules without reinitializing DI scope',
      () async {
        final di = GetIt.instance;
        await di.reset(dispose: false);

        final registry = CanonicalModuleRegistryService<int, _Cfg>();
        final module = _ScopedMountedModule();

        await module.initialize();
        await module.activate();

        expect(di.hasScope(module.runtimeType.toString()), isTrue);
        expect(module.initializeCalls, 1);
        expect(module.activateCalls, 1);

        await registry.sync([module]);

        expect(module.initializeCalls, 1);
        expect(module.activateCalls, 1);
        expect(registry.isActive(module), isTrue);

        await registry.sync(const <Module<int, _Cfg>>[]);
        expect(module.deactivateCalls, 1);
      },
    );

    test(
      'sync activates externally mounted but inactive module',
      () async {
        final di = GetIt.instance;
        await di.reset(dispose: false);

        final registry = CanonicalModuleRegistryService<int, _Cfg>();
        final module = _ScopedMountedModule();

        await module.initialize();
        expect(module.initializeCalls, 1);
        expect(module.activateCalls, 0);

        await registry.sync([module]);

        expect(module.initializeCalls, 1);
        expect(module.activateCalls, 1);
        expect(registry.isActive(module), isTrue);
      },
    );

    test('forceDispose disposes module instead of warm deactivating', () async {
      final registry = CanonicalModuleRegistryService<int, _Cfg>();
      final module = _ScopedMountedModule();

      await registry.sync([module]);
      expect(module.activateCalls, 1);

      await registry.forceDispose(module);

      expect(module.freeCalls, 1);
      expect(module.deactivateCalls, 0);
      expect(registry.isActive(module), isFalse);
      expect(registry.getByType(_ScopedMountedModule), isNull);
    });

    test('sync warm-deactivates and reactivates without cold start', () async {
      await GetIt.instance.reset(dispose: false);
      final registry = CanonicalModuleRegistryService<int, _Cfg>();
      final module = _ScopedMountedModule();

      await registry.sync([module]);
      await registry.sync(const <Module<int, _Cfg>>[]);
      await registry.sync([module]);

      expect(module.initializeCalls, 1);
      expect(module.activateCalls, 2);
      expect(module.deactivateCalls, 1);
      expect(module.freeCalls, 0);
      expect(registry.isActive(module), isTrue);
    });
  });
}

class _Cfg {
  const _Cfg();
}

abstract class _TrackingModule extends Module<int, _Cfg> {
  _TrackingModule(
    this.id, {
    required this.events,
    List<Module<int, _Cfg>> deps = const <Module<int, _Cfg>>[],
    this.initializeDelay = Duration.zero,
    this.activateDelay = Duration.zero,
    this.deactivateDelay = Duration.zero,
  }) : _deps = deps;

  final String id;
  final List<String> events;
  List<Module<int, _Cfg>> _deps;

  final Duration initializeDelay;
  final Duration activateDelay;
  final Duration deactivateDelay;

  int initializeCalls = 0;
  int activateCalls = 0;
  int deactivateCalls = 0;

  @override
  String get group => '${super.group}._TrackingModule';

  void setDeps(List<Module<int, _Cfg>> deps) {
    _deps = deps;
  }

  @override
  List<Module<int, _Cfg>> get imports => _deps;

  @override
  Future<void> initialize() async {
    initializeCalls++;
    events.add('initialize:$id');
    if (initializeDelay > Duration.zero) {
      await Future<void>.delayed(initializeDelay);
    }
  }

  @override
  Future<void> activate() async {
    activateCalls++;
    events.add('activate:$id');
    if (activateDelay > Duration.zero) {
      await Future<void>.delayed(activateDelay);
    }
  }

  @override
  Future<void> deactivate() async {
    deactivateCalls++;
    events.add('deactivate:$id');
    if (deactivateDelay > Duration.zero) {
      await Future<void>.delayed(deactivateDelay);
    }
  }

  @override
  Future<void> dependenciesChanged() async {}

  @override
  List<Route<int, _Cfg>> get routes => const <Route<int, _Cfg>>[];
}

class _FeatureModule extends _TrackingModule {
  _FeatureModule(
    super.id, {
    required super.events,
    super.deps,
    super.initializeDelay,
    super.activateDelay,
    super.deactivateDelay,
  });

  @override
  String get logTag => '_FeatureModule';
}

class _SettingsModule extends _TrackingModule {
  _SettingsModule(
    super.id, {
    required super.events,
    super.deps,
    super.initializeDelay,
    super.activateDelay,
    super.deactivateDelay,
  });

  @override
  String get logTag => '_SettingsModule';
}

class _DependencyModule extends _TrackingModule {
  _DependencyModule(
    super.id, {
    required super.events,
    super.deps,
    super.initializeDelay,
    super.activateDelay,
    super.deactivateDelay,
  });

  @override
  String get logTag => '_DependencyModule';
}

class _SharedModule extends _TrackingModule {
  _SharedModule(
    super.id, {
    required super.events,
    super.deps,
    super.initializeDelay,
    super.activateDelay,
    super.deactivateDelay,
  });

  @override
  String get logTag => '_SharedModule';
}

class _LeafModule extends _TrackingModule {
  _LeafModule(
    super.id, {
    required super.events,
    super.deps,
    super.initializeDelay,
    super.activateDelay,
    super.deactivateDelay,
  });

  @override
  String get logTag => '_LeafModule';
}

class _CycleAModule extends _TrackingModule {
  _CycleAModule(
    super.id, {
    required super.events,
    super.deps,
    super.initializeDelay,
    super.activateDelay,
    super.deactivateDelay,
  });

  @override
  String get logTag => '_CycleAModule';
}

class _CycleBModule extends _TrackingModule {
  _CycleBModule(
    super.id, {
    required super.events,
    super.deps,
    super.initializeDelay,
    super.activateDelay,
    super.deactivateDelay,
  });

  @override
  String get logTag => '_CycleBModule';
}

class _ScopedMountedModule extends Module<int, _Cfg> {
  int initializeCalls = 0;
  int activateCalls = 0;
  int deactivateCalls = 0;
  int freeCalls = 0;
  bool _active = false;

  @override
  Future<void> initialize() async {
    initializeCalls++;
    await super.initialize();
  }

  @override
  Future<void> activate() async {
    if (!_active) {
      activateCalls++;
      _active = true;
    }
    await super.activate();
  }

  @override
  Future<void> deactivate() async {
    if (_active) {
      deactivateCalls++;
      _active = false;
    }
    await super.deactivate();
  }

  @override
  Future<void> free() async {
    freeCalls++;
    await super.free();
  }

  @override
  Future<void> dependenciesChanged() async {}

  @override
  List<Route<int, _Cfg>> get routes => const <Route<int, _Cfg>>[];

  @override
  String get logTag => '_ScopedMountedModule';
}
