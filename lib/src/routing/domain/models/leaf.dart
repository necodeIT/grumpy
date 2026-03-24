import 'dart:async';

import 'package:grumpy/grumpy.dart';

// this is the base class for views.
// ignore: views_must_extend_view, views_must_have_view_suffix
/// The presentation contract for a route of type [T].
///
/// Defines how a route renders a preview and its final content.
///
/// Routing needs a framework-neutral rendering abstraction that supports both
/// placeholder and final presentation phases.
///
/// [preview] renders a synchronous placeholder, while [content] builds the
/// final presentation once routing has completed validation and activation.
///
/// [preview] must stay side-effect free because module-scoped dependencies may
/// not be ready yet.
///
/// - `T`: the presentation type returned by the leaf.
/// - [ctx]: the current routing context.
///
/// For example:
/// ```dart
/// class SettingsLeaf extends Leaf<Object> {
///   @override
///   Object preview(RouteContext ctx) => const Object();
///
///   @override
///   Object content(RouteContext ctx) => const Object();
/// }
/// ```
///
/// {@category routing}

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
