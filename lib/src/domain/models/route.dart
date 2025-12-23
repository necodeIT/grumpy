import 'package:meta/meta.dart';
import 'package:modular_foundation/modular_foundation.dart';

/// A node in the routing tree of a [Module]-based application.
///
/// A [Route] describes:
/// - the matching [path]
/// - optional [middleware] that must succeed before activation
/// - optional [children] that are resolved relative to this route's [path]
///
/// The type parameter [T] usually corresponds to the concrete presentation type
/// produced by the route (e.g. a `Widget` in Flutter).
class Route<T, Config extends Object> extends Model {
  /// The path segment used to match this route.
  ///
  /// This is interpreted relative to the parent route. For top-level routes
  /// this is usually the leading path segment (e.g. `/home` or `/settings`).
  final String path;

  /// Guards that must all pass before this route can be activated.
  ///
  /// If any [Middleware.canActivate] returns `false`, the route is considered
  /// not accessible and the navigation should be aborted or redirected if [Middleware.redirectTo] is set.
  final List<Middleware> middleware;

  /// Child routes that are matched relative to this route's [path].
  ///
  /// Use [children] to build nested routing hierarchies, where each child
  /// can define its own guards and sub-routes.
  final List<Route<T, Config>> children;

  /// Creates a [Route] with the given [path], optional [children] and [middleware].
  const Route({
    required this.path,
    this.children = const [],
    this.middleware = const [],
  });

  /// Creates a root [Route] with the given [children].
  @internal
  factory Route.root(List<Route<T, Config>> children) =>
      Route<T, Config>(path: '/', children: children);

  @override
  String toString() {
    return 'Route(path: $path, middleware: $middleware, children: $children)';
  }
}

/// A route that activates a [Module] when matched.
///
/// Use [ModuleRoute] for feature- or domain-level entry points that should
/// mount a dedicated [Module] (and its dependency graph) on navigation.
class ModuleRoute<T, Config extends Object> extends Route<T, Config> {
  /// The module that will be mounted when this route is activated.
  final Module<T, Config> module;

  final LeafRoute<T, Config>? root;

  /// Creates a [ModuleRoute] for the given [path] and [module].
  ///
  /// Optional [middleware] can be used to protect access to the module.
  const ModuleRoute({
    required super.path,
    required this.module,
    super.middleware,
    this.root,
  });

  @override
  String toString() {
    return 'ModuleRoute(path: $path, module: $module, middleware: $middleware)';
  }
}
