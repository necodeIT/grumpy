import 'dart:async';

import 'package:grumpy/grumpy.dart';

// this is the base class for views.
// ignore: views_must_extend_view, views_must_have_view_suffix
/// The presentation of a route of type [T].
abstract class Leaf<T> extends Model {
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
  FutureOr<T> content(RouteContext ctx);
}

// this is an extension of Route and not a view.
// ignore: views_must_extend_view, views_must_have_view_suffix
