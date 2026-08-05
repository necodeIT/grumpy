export '../shared/shared.dart';
export 'domain/services/services.dart';
export '../repo/repo.dart';
export '../repo/domain/domain.dart';
export '../repo/mixins/mixins.dart';
export '../routing/routing.dart';
export '../telemetry/telemetry.dart';
export '../cache/cache.dart';
export '../persistence/persistence.dart';
export '../transactions/transactions.dart';
export '../presentation/presentation.dart';

import 'dart:async';

import 'package:get_it/get_it.dart' hide Disposable;
import 'package:grumpy/src/transactions/infra/services/services.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:grumpy/grumpy.dart';
import 'package:grumpy/src/cache/infra/services/default_cache_pipeline_service.dart';
import 'package:grumpy/src/module/infra/services/canonical_module_registry_service.dart';
import 'package:grumpy/src/persistence/infra/services/default_repo_bootstrap_service.dart';
import 'package:grumpy/src/persistence/infra/services/noop_repo_state_persistence_service.dart';
import 'package:grumpy/src/routing/infra/services/routing_kit_routing_service.dart';
import 'package:grumpy/src/telemetry/infra/services/noop_analytics_service.dart';
import 'package:grumpy/src/telemetry/infra/services/noop_telemetry_service.dart';
import 'package:grumpy/src/cache/infra/services/no_op_memory_cache_layer_service.dart';
import 'package:grumpy/src/cache/infra/services/no_op_file_cache_layer_service.dart';

/// {@template module_route_config_types}
/// `RouteType` is the presentation type returned by this module's routes, and
/// `Config` is the configuration object resolved from DI during binding.
/// {@endtemplate}
///
/// {@template module_lifecycle_notes}
/// Lifecycle-managed injectables must be singletons, repos are registered as
/// async lazy singletons and initialized before first use, and `destroy()`
/// tears down the module's DI scope.
/// {@endtemplate}
///
/// A modular unit of functionality within an application.
///
/// Defines one feature's DI scope, routes, lifecycle-managed dependencies, and
/// imported module graph.
///
/// Feature composition should live in one runtime boundary instead of being
/// scattered across app startup code.
///
/// [Module] creates a scoped `GetIt` container, binds external dependencies,
/// services, datasources, and repos, then activates or deactivates them in a
/// deterministic order.
///
/// {@macro module_lifecycle_notes}
///
/// {@macro module_route_config_types}
///
/// For example:
/// ```dart
/// class SettingsModule extends Module<Object, AppConfig> {
///   @override
///   List<Route<Object, AppConfig>> get routes => const [];
/// }
/// ```
///
/// {@category module}

abstract class Module<RouteType, Config extends Object>
    with LifecycleMixin, LogMixin, Disposable {
  GetIt get _di => GetIt.instance;

  bool _isActive = false;
  bool _isActivating = false;
  bool _isInitializing = false;

  @override
  String get group => 'Module';

  @override
  Level get logLevel => Level.FINEST;

  bool _disposed = false;
  final List<Future<Repo<dynamic>> Function()> _repoResolvers = [];
  final List<Future<LifecycleMixin> Function()> _injectableResolvers = [];
  final List<Repo<dynamic>> _activeRepos = [];
  final Set<Repo<dynamic>> _activeRepoSet = {};
  final List<LifecycleMixin> _activeInjectables = [];
  final Set<LifecycleMixin> _activeInjectableSet = {};
  final Set<LifecycleMixin> _initializedInjectables = {};

  /// `true` if the module is active and ready to serve its functionality.
  bool get isActive => _isActive;

  /// `true` if the module is in the process of initializing.
  bool get isInitializing => _isInitializing;

  /// `true` if the module is in the process of activating.
  bool get isActivating => _isActivating;

  /// `true` if the module has been disposed and should no longer be used.
  bool get isDisposed => _disposed;

  /// `true` if the module is active and not in the process of initializing or activating.
  bool get isReady => isActive && !isInitializing && !isActivating;

  /// Override this getter to declare module dependencies.
  ///
  /// Dependency mounting and activation are orchestrated by
  /// [ModuleRegistryService].
  List<Module<RouteType, Config>> get imports => const [];

  /// Override this method to bind external dependencies, such as dio configurations,
  /// http clients, or other third-party services.
  ///
  /// Called first during module initialization.
  void bindExternalDeps(Bind<Object, Config> bind) {}

  /// Override this method to bind services specific to this module.
  ///
  /// Called after [bindExternalDeps] during module initialization.
  void bindServices(Bind<Service, Config> bind) {}

  /// Override this method to bind data sources specific to this module.
  ///
  /// Called after [bindServices] during module initialization.
  void bindDatasources(Bind<Datasource, Config> bind) {}

  /// Override this method to bind repositories specific to this module.
  ///
  /// Called after [bindDatasources] during module initialization.
  void bindRepos(Bind<Repo, Config> bind) {}

  void _bindInjectable<T extends Injectable>(
    InjectableFactory<T, Config> builder,
  ) {
    final probe = builder(_di.get<Config>(), _di.get);
    final lifecycleManaged = probe is LifecycleMixin;

    if (lifecycleManaged && !probe.singelton) {
      throw StateError(
        'Lifecycle-capable injectable ${probe.runtimeType} must be singleton. '
        'Set singelton => true or remove LifecycleMixin.',
      );
    }

    if (probe.singelton) {
      _di.registerLazySingleton<T>(() {
        if (lifecycleManaged &&
            !_isActive &&
            !_isActivating &&
            !_isInitializing) {
          throw StateError(
            'Lifecycle-managed injectable ${probe.runtimeType} cannot be resolved '
            'before $logTag.activate() completes.',
          );
        }
        return builder(_di.get<Config>(), _di.get);
      });

      if (lifecycleManaged) {
        _injectableResolvers.add(() async => _di.get<T>() as LifecycleMixin);
      }
    } else {
      _di.registerFactory<T>(() => builder(_di.get<Config>(), _di.get));
    }
  }

  @mustCallSuper
  @override
  FutureOr<void> activate() async {
    if (_isActive) return;

    _isActivating = true;
    try {
      for (final resolveInjectable in _injectableResolvers) {
        final injectable = await resolveInjectable();
        if (_initializedInjectables.add(injectable)) {
          await injectable.initialize();
        }
        if (_activeInjectableSet.add(injectable)) {
          await injectable.activate();
          _activeInjectables.add(injectable);
        }
      }

      for (final resolveRepo in _repoResolvers) {
        final repo = await resolveRepo();
        if (_activeRepoSet.add(repo)) {
          await repo.activate();
          _activeRepos.add(repo);
        }
      }
      _isActive = true;
    } catch (e, s) {
      await _rollbackFailedActivation(e, s);
      rethrow;
    } finally {
      _isActivating = false;
    }
  }

  Future<void> _rollbackFailedActivation(Object error, StackTrace stack) async {
    log(
      'Activation failed. Rolling back activated dependencies.',
      error,
      stack,
    );

    for (final repo in _activeRepos.reversed) {
      try {
        await repo.deactivate();
      } catch (e, s) {
        log('Rollback deactivate failed for repo ${repo.runtimeType}', e, s);
      }
    }
    _activeRepos.clear();
    _activeRepoSet.clear();

    for (final injectable in _activeInjectables.reversed) {
      try {
        await injectable.deactivate();
      } catch (e, s) {
        log(
          'Rollback deactivate failed for injectable ${injectable.runtimeType}',
          e,
          s,
        );
      }
    }
    _activeInjectables.clear();
    _activeInjectableSet.clear();

    _isActive = false;
  }

  @mustCallSuper
  @override
  FutureOr<void> deactivate() async {
    if (!_isActive) return;

    for (final repo in _activeRepos.reversed) {
      await repo.deactivate();
    }
    _activeRepos.clear();
    _activeRepoSet.clear();

    for (final injectable in _activeInjectables.reversed) {
      await injectable.deactivate();
    }
    _activeInjectables.clear();
    _activeInjectableSet.clear();

    _isActive = false;
  }

  @override
  FutureOr<void> dependenciesChanged() async {
    if (!_isActive) return;

    for (final injectable in _activeInjectables) {
      await injectable.dependenciesChanged();
    }

    for (final repo in _activeRepos) {
      await repo.dependenciesChanged();
    }
  }

  @mustCallSuper
  @override
  FutureOr<void> initialize() async {
    if (_isInitializing) return;

    log('Initializing...');

    _isInitializing = true;

    try {
      _di.pushNewScope(scopeName: runtimeType.toString(), dispose: destroy);

      log('Binding external dependencies');
      bindExternalDeps(<T extends Object>(builder) {
        _di.registerSingleton<T>(builder(_di.get<Config>(), _di.get));
      });

      log('Binding services');
      bindServices(<T extends Service>(InjectableFactory<T, Config> builder) {
        _bindInjectable<T>(builder);
      });

      log('Binding datasources');
      bindDatasources(<T extends Datasource>(
        InjectableFactory<T, Config> builder,
      ) {
        _bindInjectable<T>(builder);
      });

      log('Binding repositories');
      bindRepos(<T extends Repo>(InjectableFactory<Repo, Config> builder) {
        _repoResolvers.add(() async => await _di.getAsync<T>());

        _di.registerLazySingletonAsync<T>(
          () async {
            final repo = builder(_di.get<Config>(), _di.get);

            await repo.initialize();
            return repo as T;
          },
          dispose: (repo) async {
            await repo.destroy();
          },
        );
      });
    } catch (e, s) {
      log('Error during initialization', e, s);
      if (_di.hasScope(runtimeType.toString())) {
        _disposed = true;
        await _di.popScopesTill(runtimeType.toString());
      }
      rethrow;
    } finally {
      _isInitializing = false;
      log('Initialization complete.');
    }
  }

  @override
  @mustCallSuper
  FutureOr<void> destroy() async {
    if (_disposed) return;
    _disposed = true;

    await super.destroy();

    if (_di.hasScope(runtimeType.toString())) {
      await _di.popScopesTill(runtimeType.toString());
    }
  }

  /// The routes provided by this module.
  List<Route<RouteType, Config>> get routes;

  @override
  String toString() => '$logTag<$RouteType,$Config>';
}

/// Function signature used by module binding methods.
///
/// Describes how modules register services, datasources, or repos.
///
/// A single binding callback shape keeps `bindServices`, `bindDatasources`, and
/// related methods consistent.
///
/// The callback receives a typed [InjectableFactory] for the requested base
/// class.
///
/// The concrete DI lifetime still comes from the resolved type's
/// [Injectable.singelton] policy or repo-specific module behavior.
///
/// `Base` is the kind of thing being registered, and `Config` is the module
/// configuration available to the factory.
///
/// For example:
/// ```dart
/// void bindServices(Bind<Service, AppConfig> bind) {}
/// ```
///
/// {@category module}

typedef Bind<Base extends Object, Config extends Object> =
    void Function<T extends Base>(InjectableFactory<T, Config> builder);

/// Factory signature used to build module-managed objects.
///
/// Describes how a module constructs one injectable instance.
///
/// Builders need access to both the module config and already-registered
/// dependencies.
///
/// The function receives the active [Config] and a [Resolver] callback.
///
/// Factories should stay side-effect free except for object construction.
///
/// `T` is the type being created, and `Config` is the configuration object
/// passed to the builder.
///
/// For example:
/// ```dart
/// (cfg, resolve) => SettingsRepo(resolve<SettingsDatasource>())
/// ```
///
/// {@category module}

typedef InjectableFactory<T, Config extends Object> =
    T Function(Config cfg, Resolver resolve);

/// Typed dependency resolver passed into binding factories.
///
/// Resolves another DI-managed dependency during object construction.
///
/// Builders should depend on a narrow resolver abstraction rather than the full
/// container API.
///
/// The callback is generic and returns the requested type from the active DI
/// scope.
///
/// It is intended for use during factory execution, not as a general-purpose
/// service locator.
///
/// `T` is the dependency type to resolve.
///
/// For example:
/// ```dart
/// final analytics = resolve<AnalyticsService>();
/// ```
///
/// {@category module}

typedef Resolver = T Function<T extends Object>();

/// The root module of any Grumpy application.
///
/// Adds application-wide configuration and default builders for Grumpy's core
/// runtime services.
///
/// Every app needs one place to bind shared infrastructure such as routing,
/// telemetry, cache, persistence, and transaction support.
///
/// [RootModule] extends [Module] and exposes overridable builder getters for
/// each core service.
///
/// The defaults are intentionally safe no-op or baseline implementations. Real
/// apps usually override at least telemetry, analytics, and file-backed
/// persistence or cache services.
///
/// {@macro module_route_config_types}
///
/// For example:
/// ```dart
/// class AppModule extends RootModule<Object, AppConfig> {
///   AppModule(super.cfg);
/// }
/// ```
///
/// {@category module}

abstract class RootModule<RouteType, Config extends Object>
    extends Module<RouteType, Config> {
  /// Creates a new [RootModule] with the given [cfg].
  RootModule(this.cfg);

  /// The configuration to use throughout the application.
  final Config cfg;

  /// Creates the telemetry service instance.
  ///
  /// Override this method to enable telemetry.
  ///
  /// By default, it returns a no-op implementation.
  InjectableFactory<TelemetryService, Config> get telemetryServiceBuilder =>
      (cfg, _) => NoopTelemetryService();

  /// Creates the analytics service instance.
  ///
  /// Override this method to enable analytics.
  ///
  /// By default, it returns a no-op implementation.
  InjectableFactory<AnalyticsService, Config> get analyticsServiceBuilder =>
      (cfg, _) => NoopAnalyticsService();

  /// Creates the module registry service instance.
  ///
  /// Override this method to provide a custom module registry implementation.
  /// By default, it returns [CanonicalModuleRegistryService].
  InjectableFactory<ModuleRegistryService<RouteType, Config>, Config>
  get moduleRegistryServiceBuilder =>
      (cfg, _) => CanonicalModuleRegistryService<RouteType, Config>();

  /// Creates the routing service instance.
  ///
  /// Override this method to provide a custom routing service implementation.
  /// By default, it returns a [RoutingKitRoutingService] using the root
  /// module's routes and the registered [ModuleRegistryService].
  InjectableFactory<RoutingService<RouteType, Config>, Config>
  get routingServiceBuilder =>
      (cfg, resolve) => RoutingKitRoutingService<RouteType, Config>(
        this,
        moduleRegistry: resolve<ModuleRegistryService<RouteType, Config>>(),
      );

  /// Creates the in-memory cache layer service instance.
  InjectableFactory<MemoryCacheLayerService, Config>
  get memoryCacheLayerServiceBuilder =>
      (_, _) => const NoOpMemoryCacheLayerService();

  /// Creates the optional file cache layer service instance.
  InjectableFactory<FileCacheLayerService, Config>?
  get fileCacheLayerServiceBuilder =>
      (_, _) => const NoOpFileCacheLayerService();

  /// Creates the cache pipeline service instance.
  InjectableFactory<CachePipelineService, Config>
  get cachePipelineServiceBuilder =>
      (cfg, resolve) => DefaultCachePipelineService(
        memoryLayer: resolve<MemoryCacheLayerService>(),
        fileLayer: fileCacheLayerServiceBuilder == null
            ? null
            : resolve<FileCacheLayerService>(),
      );

  /// Creates the repo snapshot persistence service instance.
  InjectableFactory<RepoStatePersistenceService, Config>
  get repoStatePersistenceServiceBuilder =>
      (cfg, _) => NoopRepoStatePersistenceService();

  /// Creates the repo bootstrap orchestrator service instance.
  InjectableFactory<RepoBootstrapService, Config>
  get repoBootstrapServiceBuilder =>
      (cfg, resolve) => DefaultRepoBootstrapService(
        persistenceService: resolve<RepoStatePersistenceService>(),
      );

  /// Creates the transaction-engine factory service instance.
  ///
  /// Override this to customize engine selection/creation strategy.
  InjectableFactory<TxEngineFactoryService, Config>
  get txEngineFactoryServiceBuilder =>
      (cfg, _) => DefaultTxEngineFactoryService();

  @override
  FutureOr<void> initialize() {
    _di.registerSingleton<Config>(cfg);

    _isInitializing = true;
    try {
      _bindInjectable<TelemetryService>(telemetryServiceBuilder);
      _bindInjectable<AnalyticsService>(analyticsServiceBuilder);
      _bindInjectable<ModuleRegistryService<RouteType, Config>>(
        moduleRegistryServiceBuilder,
      );
      _bindInjectable<RoutingService<RouteType, Config>>(routingServiceBuilder);
      _di.registerLazySingleton<DependencyReadiness>(
        () => _di.get<RoutingService<RouteType, Config>>(),
      );
      _bindInjectable<MemoryCacheLayerService>(memoryCacheLayerServiceBuilder);
      if (fileCacheLayerServiceBuilder != null) {
        _bindInjectable<FileCacheLayerService>(fileCacheLayerServiceBuilder!);
      }
      _bindInjectable<CachePipelineService>(cachePipelineServiceBuilder);
      _bindInjectable<RepoStatePersistenceService>(
        repoStatePersistenceServiceBuilder,
      );
      _bindInjectable<RepoBootstrapService>(repoBootstrapServiceBuilder);
      _bindInjectable<TxEngineFactoryService>(txEngineFactoryServiceBuilder);
    } catch (e, s) {
      log('Failed to initialize $logTag', e, s);
    } finally {
      _isInitializing = false;
    }

    return super.initialize();
  }

  /// The root route of this module.
  Route<RouteType, Config> get root => routes.root ?? Route.root(routes);

  @nonVirtual
  @override
  // if the root module is disposed, something is very wrong.
  // ignore: must_call_super
  FutureOr<void> destroy() {
    throw StateError(
      'RootModule should not be disposed. It lives throughout the application lifecycle.',
    );
  }

  @override
  String get group => '${super.group}.RootModule';

  /// Retrieves the module configuration from the dependency injector.
  static T getConfig<T extends Object>() {
    return GetIt.instance.get<T>();
  }

  Future<void>? _bootstrapFuture;

  /// Initializes and activates the root module and its imported module graph.
  ///
  /// Use this once during application startup instead of calling [initialize]
  /// and [activate] directly. Concurrent and repeated calls share the same
  /// bootstrap operation.
  Future<void> bootstrap() {
    return _bootstrapFuture ??= _bootstrap();
  }

  Future<void> _bootstrap() async {
    await initialize();
    await ModuleRegistryService<RouteType, Config>().ensureActive(this);
  }
}
