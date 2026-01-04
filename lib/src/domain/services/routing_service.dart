import 'package:grumpy/grumpy.dart';

/// A service responsible for managing application routing.
/// Note: This router is only responsible for marking routes as active and
/// parsing paths. It does not handle any UI-related logic.
///
/// [T] represents the type of the presentation (e.g., Widget).
/// [Config] represents the configuration type used in modules.
abstract class RoutingService<T, Config extends Object> extends Service {
  /// Returns the root route of the application with all its nested routes expanded.
  Route<T, Config> get root;

  /// Navigates to the specified [path] and invokes the [callback] with the built presentation.
  /// If [skipPreview] is true, the preview phase is skipped and [callback] is called only after the final build phase.
  Future<void> navigate(
    String path, {
    bool skipPreview = false,
    required void Function(T, bool) callback,
  });

  /// Checks if the specified [path] is currently active.
  ///
  /// If [exact] is true (default), checks for an exact match; otherwise, checks for a partial match.
  /// An exact match means the current route's full path matches [path] exactly. A partial match
  /// means the current route's full path starts with [path].
  ///
  /// If [ignoreParams] is true, query parameters and fragments are ignored during the match.
  /// Default is false.
  bool isActive(String path, {bool exact = true, bool ignoreParams = false});

  /// Returns the current routing context, or null if no route is active.
  RouteContext? get currentContext;

  /// Returns the current routing context.
  /// Throws an error if no route is active.
  RouteContext get requiredCurrentContext => currentContext!;

  /// Adds a listener that is called on routing changes.
  ///
  /// The [listener] receives the new active [Route] as a parameter.
  void addListener(void Function(Route<T, Config> route) listener);

  /// Removes a previously added routing listener.
  void removeListener(void Function(Route<T, Config> route) listener);
}
