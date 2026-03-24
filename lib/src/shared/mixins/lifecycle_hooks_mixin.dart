import 'dart:async';

import 'package:meta/meta.dart';
import 'package:grumpy/grumpy.dart';

/// {@template lifecycle_hook_order_note}
/// It is unsafe to coordinate shared mutable state across multiple hooks of the
/// same phase, because registration order is not a stable dependency contract.
/// Prefer a single hook when related work must stay coupled.
/// {@endtemplate}
///
/// Hook registry for [LifecycleMixin] phases.
///
/// Lets a type register multiple callbacks for each lifecycle phase instead of
/// hand-writing one large lifecycle method.
///
/// Cross-cutting mixins often need to extend lifecycle behavior without
/// fighting over a single override.
///
/// Hook lists are recorded per phase and executed from the corresponding
/// lifecycle methods.
///
/// Hook order should not be treated as a coordination mechanism for shared
/// mutable state.
///
/// For example:
/// ```dart
/// onActivate(() async {
///   log('Activated');
/// });
/// ```
///
/// {@category shared}

mixin LifecycleHooksMixin on LifecycleMixin, LogMixin {
  final List<FutureOr<void> Function()> _initializeHooks = [];
  final List<FutureOr<void> Function()> _activateHooks = [];
  final List<FutureOr<void> Function()> _deactivateHooks = [];
  final List<FutureOr<void> Function()> _dependenciesChangedHooks = [];
  final List<FutureOr<void> Function()> _disposeHooks = [];

  /// Registers a hook to be called in [initialize].
  ///
  /// {@macro lifecycle_hook_order_note}
  void onInitialize(FutureOr<void> Function() hook) {
    _initializeHooks.add(hook);
  }

  /// Registers a hook to be called in [activate].
  ///
  /// {@macro lifecycle_hook_order_note}
  void onActivate(FutureOr<void> Function() hook) {
    _activateHooks.add(hook);
  }

  /// Registers a hook to be called in [deactivate].
  ///
  /// {@macro lifecycle_hook_order_note}
  void onDeactivate(FutureOr<void> Function() hook) {
    _deactivateHooks.add(hook);
  }

  /// Registers a hook to be called in [dependenciesChanged].
  ///
  /// {@macro lifecycle_hook_order_note}
  void onDependenciesChanged(FutureOr<void> Function() hook) {
    _dependenciesChangedHooks.add(hook);
  }

  /// Registers a hook to be called in [destroy].
  ///
  /// {@macro lifecycle_hook_order_note}
  void onDisposed(FutureOr<void> Function() hook) {
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
  FutureOr<void> destroy() async {
    await super.destroy();

    _initializeHooks.clear();
    _activateHooks.clear();
    _deactivateHooks.clear();
    _dependenciesChangedHooks.clear();

    await _runHooks('dispose', _disposeHooks);
    _disposeHooks.clear();
  }
}

/// Hook registry for repo state emissions.
///
/// Registers callbacks that run when a repo emits data, loading, or error
/// states.
///
/// Repo-related behavior such as persistence and cache invalidation should be
/// attachable without overriding repo methods directly.
///
/// The mixin stores hook lists and executes them from
/// [RepoLifecycleMixin.onEmitData], [RepoLifecycleMixin.onEmitError], and
/// [RepoLifecycleMixin.onEmitLoading].
///
/// Hooks are fire-and-forget from the caller's perspective; ordering between
/// hooks should not be relied on for shared state.
///
/// The type parameter `T` is the repo's data type.
///
/// For example:
/// ```dart
/// onData((value) {
///   log('Received $value');
/// });
/// ```
///
/// {@category shared}

mixin RepoLifecycleHooksMixin<T> on RepoLifecycleMixin<T> {
  final List<FutureOr<void> Function(T data)> _onDataHooks = [];
  final List<FutureOr<void> Function(Object error, StackTrace? stackTrace)>
  _onErrorHooks = [];
  final List<FutureOr<void> Function()> _onLoadingHooks = [];

  /// Registers a hook to be called when new data is emitted.
  void onData(FutureOr<void> Function(T data) hook) {
    _onDataHooks.add(hook);
  }

  /// Registers a hook to be called when an error occurs.
  void onError(
    FutureOr<void> Function(Object error, StackTrace? stackTrace) hook,
  ) {
    _onErrorHooks.add(hook);
  }

  /// Registers a hook to be called when loading state is emitted.
  void onLoading(FutureOr<void> Function() hook) {
    _onLoadingHooks.add(hook);
  }

  @override
  void onEmitData(T data) {
    super.onEmitData(data);
    for (final hook in _onDataHooks) {
      hook(data);
    }
  }

  @override
  void onEmitError(Object error, StackTrace? stackTrace) {
    super.onEmitError(error, stackTrace);
    for (final hook in _onErrorHooks) {
      hook(error, stackTrace);
    }
  }

  @override
  void onEmitLoading() {
    super.onEmitLoading();
    for (final hook in _onLoadingHooks) {
      hook();
    }
  }
}
