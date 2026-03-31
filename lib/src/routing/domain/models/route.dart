import 'package:meta/meta.dart';
import 'package:grumpy/grumpy.dart';

/// A node in the routing tree of a [Module]-based application.
///
/// Represents one declarative route definition in the route tree.
///
/// The routing system needs a framework-neutral model for path matching,
/// middleware, and nesting.
///
/// A [Route] stores the relative [path], its [middleware], and child routes
/// resolved underneath it.
///
/// [Route] is a base model. Use [LeafRoute] or [ModuleRoute] for concrete
/// runtime behavior.
///
/// - `T`: the presentation type produced by the route.
/// - `Config`: the configuration type shared with modules.
/// - [path], [middleware], [children]: declarative route metadata.
///
/// For example:
/// ```dart
/// const Route<Object, AppConfig>(
///   path: '/settings',
/// );
/// ```
///
/// {@category routing}

class Route<T, Config extends Object> extends Model {
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

  /// The path segment used to match this route.
  ///
  /// This is interpreted relative to the parent route. For top-level routes
  /// this is usually the leading path segment (e.g. `/home` or `/settings`).
  final String path;

  /// Guards that must all pass before this route can be activated.
  ///
  /// If any [Middleware.call] throws, the route is considered
  /// not accessible and the navigation should be aborted.
  final List<Middleware<T, Config>> middleware;

  /// Child routes that are matched relative to this route's [path].
  ///
  /// Use [children] to build nested routing hierarchies, where each child
  /// can define its own guards and sub-routes.
  final List<Route<T, Config>> children;

  @override
  String toString() {
    return 'Route(path: $path, middleware: $middleware, children: $children)';
  }

  /// Returns a string representation of the route tree starting from this route.
  String tree([String indent = '']) {
    final buffer = StringBuffer();

    buffer.writeln('$indent├─$path (${runtimeType})');
    for (final child in children) {
      // if it's the last child, we want to use '└─' instead of '├─'
      final isLast = child == children.last;
      final childIndent = isLast ? '$indent  ' : '$indent│ ';
      buffer.write(child.tree(childIndent));
    }

    return buffer.toString();
  }
}
