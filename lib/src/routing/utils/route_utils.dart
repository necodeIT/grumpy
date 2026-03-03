import 'package:grumpy/grumpy.dart';

/// Helper extension for handling lists of routes.
///
/// {@category routing}

extension RouteX<T, Config extends Object> on List<Route<T, Config>> {
  /// Returns the root leaf route of this list or null if none is found.
  LeafRoute<T, Config>? get root {
    for (final route in this) {
      if (route is LeafRoute<T, Config> && route.isRoot) {
        return route;
      }
    }
    return null;
  }
}
