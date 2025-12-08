import 'package:meta/meta.dart';
import 'package:modular_foundation/modular_foundation.dart';

/// A node in the routing tree of a [Module]-based application.
///
/// A [Route] describes:
/// - the matching [path]
/// - optional [guards] that must succeed before activation
/// - optional [children] that are resolved relative to this route's [path]
///
/// The type parameter [T] usually corresponds to the concrete presentation type
/// produced by the route (e.g. a `Widget` in Flutter).
class Route<T> {
  /// The path segment used to match this route.
  ///
  /// This is interpreted relative to the parent route. For top-level routes
  /// this is usually the leading path segment (e.g. `/home` or `/settings`).
  final String path;

  /// Guards that must all pass before this route can be activated.
  ///
  /// If any [Guard.canActivate] returns `false`, the route is considered
  /// not accessible and the navigation should be aborted or redirected if [Guard.redirectTo] is set.
  final List<Guard> guards;

  /// Child routes that are matched relative to this route's [path].
  ///
  /// Use [children] to build nested routing hierarchies, where each child
  /// can define its own guards and sub-routes.
  final List<Route> children;

  /// Creates a [Route] with the given [path], optional [children] and [guards].
  const Route({
    required this.path,
    this.children = const [],
    this.guards = const [],
  });

  /// Creates a root [Route] with the given [children].
  @internal
  factory Route.root(List<Route<T>> children) =>
      Route<T>(path: '/', children: children);

  /// Creates a [ModuleRoute].
  const factory Route.module({
    required String path,
    required Module module,
    List<Guard> guards,
  }) = ModuleRoute<T>;

  /// Creates a [ViewRoute].
  const factory Route.view({
    required String path,
    required View<T> view,
    List<Guard> guards,
    List<Route> children,
  }) = ViewRoute<T>;
}

/// A route that activates a [Module] when matched.
///
/// Use [ModuleRoute] for feature- or domain-level entry points that should
/// mount a dedicated [Module] (and its dependency graph) on navigation.
class ModuleRoute<T> extends Route<T> {
  /// The module that will be mounted when this route is activated.
  final Module module;

  /// Creates a [ModuleRoute] for the given [path] and [module].
  ///
  /// Optional [guards] can be used to protect access to the module.
  const ModuleRoute({required super.path, required this.module, super.guards});
}

/// A route that directly renders a [View] when matched.
///
/// Use [ViewRoute] for leaf routes that don't require their own [Module]
/// and can be satisfied by a single [View].
class ViewRoute<T> extends Route<T> {
  /// The view responsible for building the presentation for this route.
  final View<T> view;

  /// Creates a [ViewRoute] for the given [path] and [view].
  ///
  /// - [guards] are evaluated before [view] is built.
  /// - [children] allow this view to act as a parent in a nested route tree.
  const ViewRoute({
    required super.path,
    required this.view,
    super.guards,
    super.children,
  });
}
