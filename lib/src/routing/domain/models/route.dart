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

  /// Returns a human-readable tree representation of this route and its children.
  ///
  /// Example:
  /// ```text
  /// / (Route)
  /// ├── /home (LeafRoute) [widget: HomePage]
  /// ├── /settings (ModuleRoute) [module: SettingsModule]
  /// │   ├── profile (LeafRoute)
  /// │   └── security (LeafRoute)
  /// └── /login (LeafRoute) [guarded: 1 middleware]
  /// ```
  String toTree() {
    final buffer = StringBuffer();
    _writeTree(buffer, prefix: '', isLast: true, isRoot: true);
    return buffer.toString();
  }

  void _writeTree(
    StringBuffer buffer, {
    required String prefix,
    required bool isLast,
    required bool isRoot,
  }) {
    final label = treeLabel();

    if (isRoot) {
      buffer.writeln(label);
    } else {
      buffer.writeln('$prefix${isLast ? '└── ' : '├── '}$label');
    }

    final childPrefix = isRoot ? '' : '$prefix${isLast ? '    ' : '│   '}';

    for (var i = 0; i < children.length; i++) {
      children[i]._writeTree(
        buffer,
        prefix: childPrefix,
        isLast: i == children.length - 1,
        isRoot: false,
      );
    }

    if (this is ModuleRoute) {
      final r = this as ModuleRoute;
      for (var i = 0; i < r.module.routes.length; i++) {
        r.module.routes[i]._writeTree(
          buffer,
          prefix: childPrefix,
          isLast: i == r.module.routes.length - 1,
          isRoot: false,
        );
      }
    }
  }

  /// Generates the label for this route in the tree representation returned by [toTree].
  @visibleForOverriding
  String treeLabel() {
    final info = treeInfo;
    final suffix = info.isEmpty ? '' : ' [${info.join(', ')}]';
    return '$path ($runtimeType)$suffix';
  }

  /// Hook for subclasses to expose extra tree/debug info.
  ///
  /// Override this in concrete route types.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// List<String> get treeInfo => ['module: $module'];
  /// ```
  @protected
  List<String> get treeInfo => [
    if (middleware.isNotEmpty) 'middleware: ${middleware.length}',
    for (var m in middleware) 'guarded by ${m.runtimeType}',
    if (children.length > 1) 'children: ${children.length}',
    if (path == '/') 'root',
  ];
}
