import 'package:modular_foundation/modular_foundation.dart';

/// A service responsible for managing application routing.
///
/// [T] represents the type of the presentation (e.g., Widget).
/// [Config] represents the configuration type used in modules.
abstract class RoutingService<T, Config extends Object> extends Service {
  /// Returns the root route of the application with all its nested routes expanded.
  Route<T, Config> get root;

  /// Resolves the list of modules required for the specified [path].
  List<Module<Config, T>> resolveRouteDependencies(String path);

  /// Navigates to the specified [path] and acquires the presentation of type [T].
  Future<T?> navigate(String path);

  /// Checks if the specified [path] is currently active.
  bool isActive(String path);

  /// Returns the current routing context.
  RoutingContext currentContext();
}
