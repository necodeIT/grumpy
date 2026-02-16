import 'package:grumpy/grumpy.dart';

/// Source used to satisfy a cache lookup.
enum CacheSource {
  /// Value came from the memory layer.
  memory,

  /// Value came from the file/persistent layer.
  file,

  /// Value came from executing the query callback.
  query,
}

/// Returned cache value with source metadata.
class CacheResult<T> extends Model {
  /// Creates a cache lookup result.
  const CacheResult({
    /// Returned value.
    required this.value,

    /// Layer/source that produced the value.
    required this.source,

    /// Whether the returned value should be treated as stale.
    required this.isStale,
  });

  /// Returned value.
  final T value;

  /// Layer/source that produced the value.
  final CacheSource source;

  /// Whether the returned value should be treated as stale.
  final bool isStale;
}
