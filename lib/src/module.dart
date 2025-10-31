export 'domain/domain.dart';
export 'utils/utils.dart';
export 'presentation/presentation.dart';

import 'package:get_it/get_it.dart' hide Disposable;
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:modular_foundation/modular_foundation.dart';

import 'dart:async';

import 'package:modular_foundation/src/infra/infra.dart';

/// A modular unit of functionality within an application.
abstract class Module<Config extends Object> with LifecycleMixin, LogMixin {
  GetIt get _di => GetIt.I;

  @override
  String? get group => "Module";

  @override
  Level get logLevel => Level.FINEST;

  bool _disposed = false;

  /// Override this getter to import other modules.
  ///
  /// Each imported module will be initialized and disposed of
  /// along with this module.
  List<Module<Config>> get imports => const [];

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

  Future<void> _mount(Module<Config> module) async {
    if (_di.hasScope(module.runtimeType.toString())) {
      log('${module.runtimeType} is already mounted. Skipping.');
      return;
    }

    log('Mounting module: ${module.runtimeType}');

    _firstImportScope ??= module.runtimeType.toString();

    await module.initialize();

    log('${module.runtimeType} mounted successfully.');
  }

  @mustCallSuper
  @override
  FutureOr<void> initialize() async {
    for (final module in imports) {
      await _mount(module);
    }

    _di.pushNewScope(scopeName: runtimeType.toString(), dispose: dispose);

    bindExternalDeps(<T extends Object>(builder) {
      _di.registerFactory<T>(() => builder(_di.get<Config>(), _di.get));
    });

    bindServices(<T extends Service>(Builder<Service, Config> builder) {
      _di.registerFactory<T>(() => builder(_di.get<Config>(), _di.get) as T);
    });

    bindDatasources(<T extends Datasource>(
      Builder<Datasource, Config> builder,
    ) {
      _di.registerFactory<T>(() => builder(_di.get<Config>(), _di.get) as T);
    });

    bindRepos(<T extends Repo>(Builder<Repo, Config> builder) {
      _di.registerLazySingletonAsync<T>(
        () async {
          final repo = builder(_di.get<Config>(), _di.get);

          await repo.initialize();
          await repo.activate();
          return repo as T;
        },
        dispose: (repo) async {
          await repo.deactivate();
          await repo.dispose();
        },
      );
    });
  }

  @override
  @mustCallSuper
  FutureOr<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    await super.dispose();

    if (_firstImportScope != null) {
      await _di.popScopesTill(_firstImportScope!);
    }
  }
}

/// A function that binds a [Builder] for a specific [Base] type with a given [Config].
typedef Bind<Base extends Object, Config extends Object> =
    void Function<T extends Base>(Builder<T, Config> builder);

/// A function that builds an instance of type [T] using the provided [Config] and [Resolver].
typedef Builder<T, Config extends Object> =
    T Function(Config cfg, Resolver resolve);

/// A function that resolves an instance of type [T].
typedef Resolver = T Function<T extends Object>();

/// The root module of any Modular Foundation application.
///
/// As the root module, it is responsible for providing the application-wide
/// configuration ([Config]) as well as setting up core services like telemetry and analytics.
abstract class RootModule<Config extends Object> extends Module<Config> {
  /// The configuration to use throughout the application.
  final Config cfg;

  /// Creates a new [RootModule] with the given [cfg].
  RootModule(this.cfg);

  /// Creates the telemetry service instance.
  ///
  /// Override this method to enable telemetry.
  ///
  /// By default, it returns a no-op implementation.
  TelemetryService createTelemetryService(Config cfg) {
    return NoopTelemetryService();
  }

  /// Creates the analytics service instance.
  ///
  /// Override this method to enable analytics.
  ///
  /// By default, it returns a no-op implementation.
  AnalyticsService createAnalyticsService(Config cfg) {
    return NoopAnalyticsService();
  }

  @override
  FutureOr<void> initialize() {
    _di.registerSingleton<Config>(cfg);
    _di.registerFactory<TelemetryService>(() => createTelemetryService(cfg));
    _di.registerFactory<AnalyticsService>(() => createAnalyticsService(cfg));

    return super.initialize();
  }
}
