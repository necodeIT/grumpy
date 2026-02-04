import 'package:grumpy/grumpy.dart';

/// A route that directly renders a [Leaf] when matched.
///
/// Use [LeafRoute] for leaf routes that don't require their own [Module]
/// and can be satisfied by a single [Leaf].
class LeafRoute<T, Config extends Object> extends Route<T, Config> {
  /// The view responsible for building the presentation for this route.
  final Leaf<T> view;

  /// Creates a [LeafRoute] for the given [path] and [view].
  ///
  /// - [guards] are evaluated before [view] is built.
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

  @override
  String toString() {
    return 'ViewRoute(path: $path, view: $view, middleware: $middleware, children: $children)';
  }
}
