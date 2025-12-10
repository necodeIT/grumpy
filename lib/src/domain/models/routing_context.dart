import 'package:meta/meta.dart';
import 'package:modular_foundation/modular_foundation.dart';

/// Contextual information about the current routing state.
@immutable
class RoutingContext extends Model {
  /// The full path of the current route.
  final String fullPath;

  /// The path parameters extracted from the route.
  final Map<String, String> pathParams;

  /// The query parameters extracted from the route.
  final Map<String, String> queryParams;

  /// Contextual information about the current routing state.
  const RoutingContext({
    required this.fullPath,
    this.pathParams = const {},
    this.queryParams = const {},
  });

  /// Retrieves a path parameter by its [key].
  String? getPathParam(String key) => pathParams[key];

  /// Retrieves a query parameter by its [key].
  String? getQueryParam(String key) => queryParams[key];

  /// Retrieves a parameter by checkings [pathParams] first, then [queryParams].
  String? get(String key) => pathParams[key] ?? queryParams[key];

  /// Retrieves a parameter by checking [pathParams] first, then [queryParams].
  String? operator [](String key) => get(key);

  /// Checks if a path parameter with the given [key] exists.
  bool hasPathParam(String key) => pathParams.containsKey(key);

  /// Checks if a query parameter with the given [key] exists.
  bool hasQueryParam(String key) => queryParams.containsKey(key);

  /// Checks if a parameter with the given [key] exists in either path or query parameters.
  bool has(String key) => hasPathParam(key) || hasQueryParam(key);

  @override
  String toString() {
    return 'RoutingContext(fullPath: $fullPath, pathParams: $pathParams, queryParams: $queryParams)';
  }
}
