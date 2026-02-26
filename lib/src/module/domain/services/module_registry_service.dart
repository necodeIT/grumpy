import 'package:grumpy/grumpy.dart';

/// Owns [Module] lifecycle orchestration across the app.
///
/// The registry is responsible for:
/// - canonicalizing module instances (one instance per module type)
/// - mounting and unmounting module graphs
/// - activating and deactivating modules
/// - tracking currently active modules
/// - exposing dependency graph state for observability/debugging
///
/// A module is considered:
/// - mounted after [Module.initialize] completes
/// - active after [Module.activate] completes
abstract class ModuleRegistryService<T, Config extends Object> extends Service {
  /// Returns the DI-registered implementation of [ModuleRegistryService].
  ///
  /// Shorthand for [Service.get].
  factory ModuleRegistryService() {
    return Service.get<ModuleRegistryService<T, Config>>();
  }

  /// Internal constructor for subclasses.
  ModuleRegistryService.internal();

  @override
  String get group => '${super.group}.ModuleRegistryService';

  /// Returns the canonical instance for [module].
  ///
  /// If another instance with the same runtime type is already known by the
  /// registry, that existing instance must be returned.
  Module<T, Config> canonicalize(Module<T, Config> module);

  /// Returns the canonical module instance for [moduleType], if registered.
  Module<T, Config>? getByType(Type moduleType);

  /// All canonical module instances tracked by runtime type.
  Map<Type, Module<T, Config>> get modulesByType;

  /// Returns `true` when [module] is currently active.
  bool isActive(Module<T, Config> module);

  /// Currently active modules.
  Set<Module<T, Config>> get activeModules;

  /// Mounted module dependency graph.
  ///
  /// The key is a mounted module and the value is the set of modules it
  /// directly depends on (its direct imports).
  Map<Module<T, Config>, Set<Module<T, Config>>> get dependencyGraph;

  /// Ensures [module] and all of its dependencies are mounted and active.
  ///
  /// Implementations must be idempotent and must operate on canonical module
  /// instances only.
  Future<void> ensureActive(Module<T, Config> module);

  /// Ensures [module] is no longer active and unmounts it when possible.
  ///
  /// Implementations may keep shared dependencies mounted while still in use
  /// and must reconcile aliases to canonical instances first.
  Future<void> ensureInactive(Module<T, Config> module);

  /// Forcefully disposes [module], bypassing warm deactivation.
  ///
  /// This should be used only when a hard teardown is required.
  /// Implementations should call [Module.destroy] instead of only deactivating.
  Future<void> forceDispose(Module<T, Config> module);

  /// Computes the transitive dependency set for [modules].
  ///
  /// The returned set should contain [modules] and all imported modules needed
  /// to mount/activate them.
  Set<Module<T, Config>> resolveDependencies(
    Iterable<Module<T, Config>> modules,
  );

  /// Reconciles module state with [requiredModules].
  ///
  /// After completion, all required modules (plus their dependencies) should be
  /// active, and no extra modules should remain active.
  Future<void> sync(Iterable<Module<T, Config>> requiredModules);

  @override
  bool get singelton => true;
}
