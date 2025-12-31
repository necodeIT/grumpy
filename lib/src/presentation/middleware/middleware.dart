// this is the base class for guards.
// ignore: guards_must_extend_guard
import 'package:meta/meta.dart';
import 'package:grumpy/grumpy.dart';

/// {@template middleware}
/// Middleware that can intercept and modify routing behavior.
///
/// In frontend frameworks, middleware can be used to guard routes and redirect
/// users based on authentication status, permissions, or other criteria.
///
/// For backend frameworks, middleware can handle tasks such as logging,
/// authentication, request modification, and response formatting.
///
/// Middleware is executed in the order it is defined, allowing for
/// layered processing of routing requests.
/// {@endtemplate}
abstract class Middleware<T, Config extends Object> with LogMixin {
  /// {@macro middleware}
  const Middleware();

  /// Intercepts a routing [context] and returns a potentially modified [RouteContext].
  Future<RouteContext> call(RouteContext context);

  @override
  @mustBeOverridden
  String toString() {
    return 'Middleware()';
  }
}
