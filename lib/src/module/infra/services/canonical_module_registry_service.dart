import 'dart:async';

import 'package:get_it/get_it.dart' hide Disposable;
import 'package:grumpy/grumpy.dart';

/// Default [ModuleRegistryService] implementation for module canonicalization
/// and lifecycle orchestration.
///
/// This registry guarantees one canonical [Module] instance per runtime type.
/// Any alias instances are reconciled to the canonical instance before
/// lifecycle operations are executed.
class CanonicalModuleRegistryService<T, Config extends Object>
    extends ModuleRegistryService<T, Config>
    with LifecycleMixin {
  /// Creates a module registry service.
  CanonicalModuleRegistryService() : super.internal();

  final Map<Type, Module<T, Config>> _modulesByType = {};
  final Map<Module<T, Config>, Set<Module<T, Config>>> _dependencyGraph = {};
  final Set<Module<T, Config>> _mountedModules = {};
  final Set<Module<T, Config>> _activeModules = {};
  final Set<Module<T, Config>> _requiredRootModules = {};

  Future<void> _pending = Future<void>.value();
  GetIt get _di => GetIt.instance;

  @override
  Map<Type, Module<T, Config>> get modulesByType =>
      Map.unmodifiable(_modulesByType);

  @override
  Set<Module<T, Config>> get activeModules => Set.unmodifiable(_activeModules);

  @override
  Map<Module<T, Config>, Set<Module<T, Config>>> get dependencyGraph {
    return Map.unmodifiable(
      _dependencyGraph.map(
        (module, deps) =>
            MapEntry(module, Set<Module<T, Config>>.unmodifiable(deps)),
      ),
    );
  }

  @override
  Module<T, Config> canonicalize(Module<T, Config> module) {
    return _canonicalize(module, <Type>{});
  }

  Module<T, Config> _canonicalize(
    Module<T, Config> module,
    Set<Type> visiting,
  ) {
    final existing = _modulesByType[module.runtimeType];
    final canonical = existing ?? module;

    if (existing == null) {
      _modulesByType[module.runtimeType] = module;
    } else if (!identical(existing, module)) {
      log(
        'Canonicalizing duplicate ${module.runtimeType}.'
        ' Using existing instance: $existing',
      );
    }

    if (!visiting.add(canonical.runtimeType)) {
      throw StateError(
        'Circular module imports detected at ${canonical.runtimeType}.',
      );
    }

    final deps = _dependencyGraph.putIfAbsent(
      canonical,
      () => <Module<T, Config>>{},
    );
    try {
      for (final imported in module.imports) {
        deps.add(_canonicalize(imported, visiting));
      }
    } finally {
      visiting.remove(canonical.runtimeType);
    }

    return canonical;
  }

  @override
  Module<T, Config>? getByType(Type moduleType) => _modulesByType[moduleType];

  @override
  bool isActive(Module<T, Config> module) {
    final canonical = _modulesByType[module.runtimeType];
    if (canonical == null) return false;
    return _activeModules.contains(canonical);
  }

  @override
  Set<Module<T, Config>> resolveDependencies(
    Iterable<Module<T, Config>> modules,
  ) {
    final resolved = <Module<T, Config>>{};

    void visit(Module<T, Config> module) {
      final canonical = canonicalize(module);
      if (!resolved.add(canonical)) return;

      final deps = _dependencyGraph[canonical] ?? <Module<T, Config>>{};

      for (final dep in deps) {
        visit(dep);
      }
    }

    for (final module in modules) {
      visit(module);
    }

    return resolved;
  }

  @override
  Future<void> ensureActive(Module<T, Config> module) {
    final canonical = canonicalize(module);
    _requiredRootModules.add(canonical);
    return _enqueueSync();
  }

  @override
  Future<void> ensureInactive(Module<T, Config> module) {
    final canonical = canonicalize(module);
    _requiredRootModules.remove(canonical);
    return _enqueueSync();
  }

  @override
  Future<void> forceDispose(Module<T, Config> module) {
    final canonical = canonicalize(module);
    return _pending = _pending.then(
      (_) async {
        _requiredRootModules.remove(canonical);
        _activeModules.remove(canonical);
        _mountedModules.remove(canonical);
        _modulesByType.remove(canonical.runtimeType);
        _dependencyGraph.remove(canonical);
        for (final deps in _dependencyGraph.values) {
          deps.remove(canonical);
        }

        await canonical.free();
      },
      onError: (e, s) {
        log('Error during forceDispose', e, s);
      },
    );
  }

  @override
  Future<void> sync(Iterable<Module<T, Config>> requiredModules) {
    log('Syncing modules: $requiredModules');
    if (requiredModules.isEmpty &&
        _requiredRootModules.isEmpty &&
        _activeModules.isEmpty) {
      log('No modules to sync.');
      return Future<void>.value();
    }

    _requiredRootModules
      ..clear()
      ..addAll(requiredModules.map(canonicalize));
    return _enqueueSync();
  }

  Future<void> _enqueueSync() {
    log('Enqueuing sync...');
    return _pending = () async {
      log('Waiting for previous sync to complete...');
      await _pending;
      await _reconcile();
    }();
  }

  Future<void> _reconcile() async {
    final required = resolveDependencies(_requiredRootModules);
    final toActivate = required.difference(_activeModules);
    final toDeactivate = _activeModules.difference(required);

    log(
      'Syncing modules: toActivate=$toActivate, toDeactivate=$toDeactivate, required=$required',
    );

    final order = _topological(required);
    for (final module in order) {
      if (!toActivate.contains(module)) continue;

      if (!_mountedModules.contains(module)) {
        if (_di.hasScope(module.runtimeType.toString())) {
          // This module was mounted through legacy module import mounting.
          // Adopt it so we don't try to create a duplicate DI scope.
          _mountedModules.add(module);
          log('Adopted externally mounted module: ${module.runtimeType}');
        } else {
          log('Initializing ${module.logTag}');

          await module.initialize();
          log('Cock');
          _mountedModules.add(module);
          log('Mounted module: ${module.runtimeType}');
        }
      }

      await module.activate();
      _activeModules.add(module);
      log('Activated module: ${module.runtimeType}');
    }

    final deactivateOrder = _topological(_activeModules).reversed;
    for (final module in deactivateOrder) {
      if (!toDeactivate.contains(module)) continue;

      await module.deactivate();
      _activeModules.remove(module);
      log('Deactivated module: ${module.runtimeType}');
    }

    log('Sync complete.');
  }

  List<Module<T, Config>> _topological(Set<Module<T, Config>> modules) {
    final ordered = <Module<T, Config>>[];
    final visiting = <Module<T, Config>>{};
    final visited = <Module<T, Config>>{};

    void visit(Module<T, Config> module) {
      if (!modules.contains(module)) return;
      if (visited.contains(module)) return;
      if (!visiting.add(module)) {
        throw StateError(
          'Circular module imports detected at ${module.runtimeType}.',
        );
      }

      final deps = _dependencyGraph[module] ?? <Module<T, Config>>{};
      for (final dep in deps) {
        visit(dep);
      }

      visiting.remove(module);
      visited.add(module);
      ordered.add(module);
    }

    for (final module in modules) {
      visit(module);
    }

    return ordered;
  }

  @override
  FutureOr<void> activate() {}

  @override
  FutureOr<void> deactivate() async {
    await sync(<Module<T, Config>>[]);
  }

  @override
  FutureOr<void> dependenciesChanged() {}

  @override
  FutureOr<void> initialize() {}

  @override
  FutureOr<void> free() async {
    await deactivate();
    await super.free();
  }

  @override
  String get logTag => 'CanonicalModuleRegistryService';
}
