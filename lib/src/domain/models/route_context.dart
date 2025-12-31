import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:grumpy/grumpy.dart';

part 'route_context.freezed.dart';
part 'route_context.g.dart';

/// Contextual information about the current routing state.
@freezed
abstract class RouteContext extends Model with _$RouteContext {
  const RouteContext._();

  /// Contextual information about the current routing state.
  const factory RouteContext({
    /// The full path of the current route.
    required String fullPath,

    /// The path parameters extracted from the route.
    @Default({}) Map<String, String> pathParams,

    /// The query parameters extracted from the route.
    @Default({}) Map<String, String> queryParams,

    /// The query parameters extracted from the route, allowing multiple values per key.
    @Default({}) Map<String, List<String>> queryParamsAll,

    /// The fragment identifier from the URL, if any.
    @Default('') String fragment,
  }) = _RouteContext;

  /// Parses the [fullPath] into a [Uri] object.
  Uri get uri => Uri.parse(fullPath);

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

  /// Creates a new [RouteContext] from a JSON map.
  factory RouteContext.fromJson(Map<String, dynamic> json) =>
      _$RouteContextFromJson(json);

  /// Creates a new [RouteContext] from a [Uri] object.
  factory RouteContext.fromUri(Uri uri) {
    return RouteContext(
      fullPath: uri.toString(),
      pathParams: {},
      queryParams: uri.queryParameters,
      queryParamsAll: uri.queryParametersAll,
      fragment: uri.fragment,
    );
  }

  /// Parses a URI string into a [RouteContext].
  factory RouteContext.parse(String uriString) {
    final uri = Uri.parse(uriString);
    return RouteContext.fromUri(uri);
  }
}
