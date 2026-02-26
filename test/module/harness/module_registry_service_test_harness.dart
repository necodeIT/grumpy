import 'dart:async';
import 'package:grumpy/grumpy.dart';

class Cfg {
  const Cfg();
}

abstract class _TrackingModule extends Module<int, Cfg> {
  _TrackingModule(
    this.id, {
    required this.events,
    List<Module<int, Cfg>> deps = const <Module<int, Cfg>>[],
    this.initializeDelay = Duration.zero,
    this.activateDelay = Duration.zero,
    this.deactivateDelay = Duration.zero,
  }) : _deps = deps;

  final String id;
  final List<String> events;
  List<Module<int, Cfg>> _deps;

  final Duration initializeDelay;
  final Duration activateDelay;
  final Duration deactivateDelay;

  int initializeCalls = 0;
  int activateCalls = 0;
  int deactivateCalls = 0;

  @override
  String get group => '${super.group}._TrackingModule';

  void setDeps(List<Module<int, Cfg>> deps) {
    _deps = deps;
  }

  @override
  List<Module<int, Cfg>> get imports => _deps;

  @override
  // Intentionally not calling super: registry tests need modules that do not
  // auto-orchestrate import lifecycle, otherwise events are double-counted.
  // ignore: must_call_super
  Future<void> initialize() async {
    initializeCalls++;
    events.add('initialize:$id');
    if (initializeDelay > Duration.zero) {
      await Future<void>.delayed(initializeDelay);
    }
  }

  @override
  // Intentionally not calling super: registry tests need modules that do not
  // auto-orchestrate import lifecycle, otherwise events are double-counted.
  // ignore: must_call_super
  Future<void> activate() async {
    activateCalls++;
    events.add('activate:$id');
    if (activateDelay > Duration.zero) {
      await Future<void>.delayed(activateDelay);
    }
  }

  @override
  // Intentionally not calling super: registry tests need modules that do not
  // auto-orchestrate import lifecycle, otherwise events are double-counted.
  // ignore: must_call_super
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
  List<Route<int, Cfg>> get routes => const <Route<int, Cfg>>[];
}

class FeatureModule extends _TrackingModule {
  FeatureModule(
    super.id, {
    required super.events,
    super.deps,
    super.initializeDelay,
    super.activateDelay,
    super.deactivateDelay,
  });

  @override
  String get logTag => 'FeatureModule';
}

class SettingsModule extends _TrackingModule {
  SettingsModule(
    super.id, {
    required super.events,
    super.deps,
    super.initializeDelay,
    super.activateDelay,
    super.deactivateDelay,
  });

  @override
  String get logTag => 'SettingsModule';
}

class DependencyModule extends _TrackingModule {
  DependencyModule(
    super.id, {
    required super.events,
    super.deps,
    super.initializeDelay,
    super.activateDelay,
    super.deactivateDelay,
  });

  @override
  String get logTag => 'DependencyModule';
}

class SharedModule extends _TrackingModule {
  SharedModule(
    super.id, {
    required super.events,
    super.deps,
    super.initializeDelay,
    super.activateDelay,
    super.deactivateDelay,
  });

  @override
  String get logTag => 'SharedModule';
}

class LeafModule extends _TrackingModule {
  LeafModule(
    super.id, {
    required super.events,
    super.deps,
    super.initializeDelay,
    super.activateDelay,
    super.deactivateDelay,
  });

  @override
  String get logTag => 'LeafModule';
}

class CycleAModule extends _TrackingModule {
  CycleAModule(
    super.id, {
    required super.events,
    super.deps,
    super.initializeDelay,
    super.activateDelay,
    super.deactivateDelay,
  });

  @override
  String get logTag => 'CycleAModule';
}

class CycleBModule extends _TrackingModule {
  CycleBModule(
    super.id, {
    required super.events,
    super.deps,
    super.initializeDelay,
    super.activateDelay,
    super.deactivateDelay,
  });

  @override
  String get logTag => 'CycleBModule';
}

class ScopedMountedModule extends Module<int, Cfg> {
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
  Future<void> destroy() async {
    freeCalls++;
    await super.destroy();
  }

  @override
  Future<void> dependenciesChanged() async {}

  @override
  List<Route<int, Cfg>> get routes => const <Route<int, Cfg>>[];

  @override
  String get logTag => 'ScopedMountedModule';
}
