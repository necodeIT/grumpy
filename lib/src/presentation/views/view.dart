import 'dart:async';

import 'package:modular_foundation/modular_foundation.dart';

// this is the base class for views.
// ignore: views_must_extend_view
/// The presentation of a route of type [T].
abstract class View<T> {
  /// Creates a [View].
  const View();

  /// Builds a preview presentation of [T] while the route is being validated.
  ///
  /// This can be used to show a loading indicator or a placeholder while
  /// a guard is being checked.
  ///
  /// Note: It is unsafe to perform navigation actions or to use
  /// any module-dependent resources in this method, as the module
  /// may not have been fully initialized yet when this method is called.
  T preview(RoutingContext ctx);

  /// Builds the final presentation of [T] once the route has been validated.
  FutureOr<T> build(RoutingContext ctx);
}

// this is an extension of Route and not a view.
// ignore: views_must_extend_view, views_must_have_view_suffix
/// A route that directly renders a [View] when matched.
///
/// Use [ViewRoute] for leaf routes that don't require their own [Module]
/// and can be satisfied by a single [View].
class ViewRoute<T, Config extends Object> extends Route<T, Config> {
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

  @override
  String toString() {
    return 'ViewRoute(path: $path, view: $view, guards: $guards, children: $children)';
  }
}
