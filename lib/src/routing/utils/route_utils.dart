import 'package:grumpy/grumpy.dart';

/// Helper extension for handling lists of routes.
///
/// Adds convenience helpers for collections of routes.
///
/// Route trees often need small derived lookups that should not live on the
/// base route model.
///
/// [root] scans the list for a [LeafRoute] whose path is `/`.
///
/// Only root [LeafRoute] entries count; module routes are ignored here.
///
/// - `T`: the presentation type.
/// - `Config`: the configuration type.
///
/// For example:
/// ```dart
/// final entryLeaf = routes.root;
/// ```
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
