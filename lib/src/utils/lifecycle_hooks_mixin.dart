import 'dart:async';

import 'package:meta/meta.dart';
import 'package:modular_foundation/modular_foundation.dart';

/// Provides lifecycle hooks for classes that mix in [LifecycleMixin].
mixin LifecycleHooksMixin on LifecycleMixin, LogMixin {
  final List<FutureOr<void> Function()> _initializeHooks = [];
  final List<FutureOr<void> Function()> _activateHooks = [];
  final List<FutureOr<void> Function()> _deactivateHooks = [];
  final List<FutureOr<void> Function()> _dependenciesChangedHooks = [];
  final List<FutureOr<void> Function()> _disposeHooks = [];

  /// Registers a hook to be called in [initialize].
  void onInitialize(FutureOr<void> Function() hook) {
    _initializeHooks.add(hook);
  }

  /// Registers a hook to be called in [activate].
  void onActivate(FutureOr<void> Function() hook) {
    _activateHooks.add(hook);
  }

  /// Registers a hook to be called in [deactivate].
  void onDeactivate(FutureOr<void> Function() hook) {
    _deactivateHooks.add(hook);
  }

  /// Registers a hook to be called in [dependenciesChanged].
  void onDependenciesChanged(FutureOr<void> Function() hook) {
    _dependenciesChangedHooks.add(hook);
  }

  /// Registers a hook to be called in [dispose].
  void onDispose(FutureOr<void> Function() hook) {
    _disposeHooks.add(hook);
  }

  Future<void> _runHooks(
    String name,
    List<FutureOr<void> Function()> hooks,
  ) async {
    final startTime = DateTime.now();
    final futures = List.of(hooks.map((hook) async => hook()));

    log('Running $name hooks (${hooks.length})');

    await Future.wait(futures);

    log(
      'Completed $name hooks (${hooks.length}) in '
      '${DateTime.now().difference(startTime).inMilliseconds} ms',
    );
  }

  @override
  FutureOr<void> initialize() async {
    await _runHooks('initialize', _initializeHooks);
  }

  @override
  FutureOr<void> activate() async {
    await _runHooks('activate', _activateHooks);
  }

  @override
  FutureOr<void> deactivate() async {
    await _runHooks('deactivate', _deactivateHooks);
  }

  @override
  FutureOr<void> dependenciesChanged() async {
    await _runHooks('dependenciesChanged', _dependenciesChangedHooks);
  }

  @override
  @mustCallSuper
  FutureOr<void> dispose() async {
    await super.dispose();

    _initializeHooks.clear();
    _activateHooks.clear();
    _deactivateHooks.clear();
    _dependenciesChangedHooks.clear();

    await _runHooks('dispose', _disposeHooks);
    _disposeHooks.clear();
  }
}
