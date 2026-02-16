export 'domain/domain.dart';
export 'utils/utils.dart';
export 'presentation/presentation.dart';

import 'package:get_it/get_it.dart' hide Disposable;
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:grumpy/grumpy.dart';

import 'dart:async';

import 'package:grumpy/src/infra/infra.dart';

/// A modular unit of functionality within an application.
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

  /// Override this getter to import other modules.
  ///
  /// Each imported module will be initialized and disposed of
  /// along with this module - unless they were already mounted by another module.
  List<Module<RouteType, Config>> get imports => const [];

  String? _firstImportScope;

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

  Future<void> _mount(Module<RouteType, Config> module) async {
    if (_di.hasScope(module.runtimeType.toString())) {
      log('${module.runtimeType} is already mounted. Skipping.');
      return;
    }

    log('Mounting module: ${module.runtimeType}');

    _firstImportScope ??= module.runtimeType.toString();

    await module.initialize();
    await module.activate();

    log('${module.runtimeType} mounted successfully.');
  }

  void _bindInjectable<T extends Injectable>(Builder<T, Config> builder) {
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
            'before $runtimeType.activate() completes.',
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

    for (final module in imports) {
      await module.activate();
    }

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
    } finally {
      _isActivating = false;
    }

    _isActive = true;
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

    for (final module in imports.reversed) {
      await module.deactivate();
    }
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
    _isInitializing = true;
    try {
      for (final module in imports) {
        await _mount(module);
      }

      _di.pushNewScope(scopeName: runtimeType.toString(), dispose: free);

      bindExternalDeps(<T extends Object>(builder) {
        _di.registerSingleton<T>(builder(_di.get<Config>(), _di.get));
      });

      bindServices(<T extends Service>(Builder<T, Config> builder) {
        _bindInjectable<T>(builder);
      });

      bindDatasources(<T extends Datasource>(Builder<T, Config> builder) {
        _bindInjectable<T>(builder);
      });

      bindRepos(<T extends Repo>(Builder<Repo, Config> builder) {
        _repoResolvers.add(() async => await _di.getAsync<T>());

        _di.registerLazySingletonAsync<T>(
          () async {
            final repo = builder(_di.get<Config>(), _di.get);

            await repo.initialize();
            return repo as T;
          },
          dispose: (repo) async {
            await repo.free();
          },
        );
      });
    } finally {
      _isInitializing = false;
    }
  }

  @override
  @mustCallSuper
  FutureOr<void> free() async {
    if (_disposed) return;
    _disposed = true;

    await super.free();

    if (_firstImportScope != null) {
      await _di.popScopesTill(_firstImportScope!);
    }
  }

  /// The routes provided by this module.
  List<Route<RouteType, Config>> get routes;
}

/// A function that binds a [Builder] for a specific [Base] type with a given [Config].
typedef Bind<Base extends Object, Config extends Object> =
    void Function<T extends Base>(Builder<T, Config> builder);

/// A function that builds an instance of type [T] using the provided [Config] and [Resolver].
typedef Builder<T, Config extends Object> =
    T Function(Config cfg, Resolver resolve);

/// A function that resolves an instance of type [T].
typedef Resolver = T Function<T extends Object>();

/// The root module of any Grumpy application.
///
/// As the root module, it is responsible for providing the application-wide
/// configuration ([Config]) as well as setting up core services like telemetry and analytics.
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
  Builder<TelemetryService, Config> get telemetryServiceBuilder =>
      (cfg, _) => NoopTelemetryService();

  /// Creates the analytics service instance.
  ///
  /// Override this method to enable analytics.
  ///
  /// By default, it returns a no-op implementation.
  Builder<AnalyticsService, Config> get analyticsServiceBuilder =>
      (cfg, _) => NoopAnalyticsService();

  /// Creates the module registry service instance.
  ///
  /// Override this method to provide a custom module registry implementation.
  /// By default, it returns [CanonicalModuleRegistryService].
  Builder<ModuleRegistryService<RouteType, Config>, Config>
  get moduleRegistryServiceBuilder =>
      (cfg, _) => CanonicalModuleRegistryService<RouteType, Config>();

  /// Creates the routing service instance.
  ///
  /// Override this method to provide a custom routing service implementation.
  /// By default, it returns a [RoutingKitRoutingService] using the root
  /// module's routes and the registered [ModuleRegistryService].
  Builder<RoutingService<RouteType, Config>, Config>
  get routingServiceBuilder =>
      (cfg, resolve) => RoutingKitRoutingService<RouteType, Config>(
        this,
        moduleRegistry: resolve<ModuleRegistryService<RouteType, Config>>(),
      );

  /// Creates the in-memory cache layer service instance.
  Builder<MemoryCacheLayerService, Config> get memoryCacheLayerServiceBuilder =>
      (cfg, _) => InMemoryCacheLayerService();

  /// Creates the optional file cache layer service instance.
  Builder<FileCacheLayerService, Config>? get fileCacheLayerServiceBuilder =>
      null;

  /// Creates the cache pipeline service instance.
  Builder<CachePipelineService, Config> get cachePipelineServiceBuilder =>
      (cfg, resolve) => DefaultCachePipelineService(
        memoryLayer: resolve<MemoryCacheLayerService>(),
        fileLayer: fileCacheLayerServiceBuilder == null
            ? null
            : resolve<FileCacheLayerService>(),
      );

  /// Creates the repo snapshot persistence service instance.
  Builder<RepoStatePersistenceService, Config>
  get repoStatePersistenceServiceBuilder =>
      (cfg, _) => NoopRepoStatePersistenceService();

  /// Creates the repo bootstrap orchestrator service instance.
  Builder<RepoBootstrapService, Config> get repoBootstrapServiceBuilder =>
      (cfg, resolve) => DefaultRepoBootstrapService(
        persistenceService: resolve<RepoStatePersistenceService>(),
      );

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
      _bindInjectable<MemoryCacheLayerService>(memoryCacheLayerServiceBuilder);
      if (fileCacheLayerServiceBuilder != null) {
        _bindInjectable<FileCacheLayerService>(fileCacheLayerServiceBuilder!);
      }
      _bindInjectable<CachePipelineService>(cachePipelineServiceBuilder);
      _bindInjectable<RepoStatePersistenceService>(
        repoStatePersistenceServiceBuilder,
      );
      _bindInjectable<RepoBootstrapService>(repoBootstrapServiceBuilder);
    } finally {
      _isInitializing = false;
    }

    return super.initialize();
  }

  /// The root route of this module.
  Route<RouteType, Config> get root => Route.root(routes);

  @nonVirtual
  @override
  // if the root module is disposed, something is very wrong.
  // ignore: must_call_super
  FutureOr<void> free() {
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
}
