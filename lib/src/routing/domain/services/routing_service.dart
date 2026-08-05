import 'dart:async';

import 'package:grumpy/grumpy.dart';
import 'package:meta/meta.dart';

/// {@template routing_type_params}
/// The type parameter `T` is the presentation type produced by routing, such
/// as a `Widget`, and `Config` is the configuration type supplied by modules
/// and the routing runtime.
/// {@endtemplate}
///
/// A service responsible for managing application routing.
///
/// Resolves navigation requests into active routes and emitted presentations.
///
/// Route matching, middleware execution, and module activation should live in
/// one runtime boundary instead of being spread across application code.
///
/// Implementations parse a path, build a [RouteContext], run middleware,
/// activate required modules, and emit preview/final view changes.
///
/// This service handles routing state and activation, not UI framework details.
///
/// {@macro routing_type_params}
///
/// For example:
/// ```dart
/// final router = RoutingService<Object, AppConfig>();
/// await router.navigate('/settings');
/// ```
///
/// {@category routing}

abstract class RoutingService<T, Config extends Object> extends Service
    implements DependencyReadiness {
  /// Returns the DI-registered implementation of [RoutingService].
  ///
  /// Shorthand for [Service.get].
  factory RoutingService() {
    return Service.get<RoutingService<T, Config>>();
  }

  /// Required for the factory pattern to work.
  @internal
  RoutingService.internal();

  /// Returns the root route of the application with all its nested routes expanded.
  Route<T, Config> get root;

  /// Navigates to the specified [path] and invokes the [callback] with the built presentation.
  /// If [skipPreview] is true, the preview phase is skipped and [callback] is called only after the final build phase.
  Future<void> navigate(
    String path, {
    bool skipPreview = false,
    void Function(T, bool) callback = noopCallback,
  });

  /// Default callback for [navigate].
  static void noopCallback(dynamic _, bool _) {}

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
  @override
  String get group => '${super.group}.RoutingService';

  /// Subscribes to view change events.
  ///
  /// The [callback] is invoked whenever the view changes, receiving a [ViewChangedEvent]
  /// that contains the new view, whether it's a preview, the current route context, and the configuration.
  ///
  /// Returns a [StreamSubscription] that can be used to cancel the subscription.
  StreamSubscription<ViewChangedEvent<T, Config>> onViewChanged(
    void Function(ViewChangedEvent<T, Config>) callback,
  );

  /// A stream of all view change events.
  Stream<ViewChangedEvent<T, Config>> get viewStream;

  /// Waits until the current route is ready and the view has been rendered.
  Future<void> get currentNavigation;

  @override
  Future<void> waitForPendingDependencies() async {
    while (true) {
      final navigation = currentNavigation;
      await navigation;
      if (identical(navigation, currentNavigation)) return;
    }
  }

  @override
  bool get singelton => true;
}

/// An event representing a change in the view rendered by the [RoutingService].
///
/// Packages the emitted view together with preview status and active context.
///
/// Routing observers need more than just the rendered view in order to react to
/// preview/final transitions.
///
/// The record contains the `view`, `isPreview` flag, optional `context`, and
/// active `config`.
///
/// `context` may be `null` when a preview is emitted before final resolution.
///
/// {@macro routing_type_params}
///
/// For example:
/// ```dart
/// router.onViewChanged((event) {
///   if (!event.isPreview) {}
/// });
/// ```
///
/// {@category routing}

typedef ViewChangedEvent<T, Config> = ({
  T view,
  bool isPreview,
  RouteContext? context,
  Config config,
});
