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
  /// **This method runs before required modules are guaranteed active.**
  ///
  /// You must not:
  /// - trigger navigation
  /// - resolve or access module-scoped dependencies (Repo/Service/Datasource)
  /// - rely on lifecycle-managed resources being initialized or activated
  ///
  /// Keep this method side-effect free and limited to static/synchronous
  /// placeholder rendering from data already available in [ctx].
  T preview(RouteContext ctx);

  /// Builds the final presentation of [T] once the route has been validated.
  FutureOr<T> content(RouteContext ctx);
}
