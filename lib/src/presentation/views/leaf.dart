import 'dart:async';

import 'package:modular_foundation/modular_foundation.dart';

// this is the base class for views.
// ignore: views_must_extend_view, views_must_have_view_suffix
/// The presentation of a route of type [T].
abstract class Leaf<T> {
  /// Creates a [Leaf].
  const Leaf();

  /// Builds a preview presentation of [T] while the route is being validated.
  ///
  /// This can be used to show a loading indicator or a placeholder while
  /// a guard is being checked.
  ///
  /// Note: It is unsafe to perform navigation actions or to use
  /// any module-dependent resources in this method, as the module
  /// may not have been fully initialized yet when this method is called.
  T preview(RouteContext ctx);

  /// Builds the final presentation of [T] once the route has been validated.
  FutureOr<T> build(RouteContext ctx);
}

// this is an extension of Route and not a view.
// ignore: views_must_extend_view, views_must_have_view_suffix
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

  @override
  String toString() {
    return 'ViewRoute(path: $path, view: $view, middleware: $middleware, children: $children)';
  }
}
