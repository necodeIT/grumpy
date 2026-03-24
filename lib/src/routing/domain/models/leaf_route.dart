import 'package:grumpy/grumpy.dart';

/// A route that directly renders a [Leaf] when matched.
///
/// Declares a route whose endpoint is a concrete [Leaf].
///
/// Not every route needs its own module boundary; some simply render one view.
///
/// [LeafRoute] extends [Route] with a [view] and optional nested children.
///
/// [LeafRoute.root] is a convenience for module entry leaves that live at `/`.
///
/// - `T`: the presentation type.
/// - `Config`: the routing/module config type.
/// - [view], [middleware], [children]: leaf-routing behavior.
///
/// For example:
/// ```dart
/// const LeafRoute<Object, AppConfig>(
///   path: '/settings',
///   view: SettingsLeaf(),
/// );
/// ```
///
/// {@category routing}

class LeafRoute<T, Config extends Object> extends Route<T, Config> {
  /// Creates a [LeafRoute] for the given [path] and [view].
  ///
  /// - [middleware] are evaluated before [view] is built.
  /// - [children] allow this view to act as a parent in a nested route tree.
  const LeafRoute({
    required super.path,
    required this.view,
    super.middleware,
    super.children,
  });

  /// Creates a root [LeafRoute] with the given [view], optional [middleware] and [children].
  /// This is a convenience constructor for defining root leaf routes in [ModuleRoute]s.
  const LeafRoute.root(this.view, {super.middleware, super.children})
    : super(path: '/');

  /// The view responsible for building the presentation for this route.
  final Leaf<T> view;

  @override
  String toString() {
    return 'LeafRoute(path: $path, view: $view, middleware: $middleware, children: $children)';
  }

  /// `true` if this route is the root route.
  bool get isRoot => path == '/';
}
