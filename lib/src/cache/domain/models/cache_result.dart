import 'package:grumpy/grumpy.dart';

/// Source used to satisfy a cache lookup.
///
/// Identifies where a resolved cache value came from.
///
/// Callers often need to know whether data came from memory, durable cache, or
/// the live query path.
///
/// The enum has one value per supported lookup source.
///
/// `query` means the pipeline had to execute the fallback read path.
///
/// For example:
/// ```dart
/// if (result.source == CacheSource.file) {}
/// ```
///
/// {@category cache}

enum CacheSource {
  /// Value came from the memory layer.
  memory,

  /// Value came from the file/persistent layer.
  file,

  /// Value came from executing the query callback.
  query,
}

/// Returned cache value with source metadata.
///
/// Packages a resolved cache value together with its source and stale flag.
///
/// A cache hit is not enough information on its own when the caller needs to
/// distinguish fresh from stale or local from queried data.
///
/// [CacheResult] stores the returned [value], the [source] that produced it,
/// and whether it should be treated as stale.
///
/// A stale result may still be returned intentionally as a fallback.
///
/// - `T`: the resolved value type.
/// - [source]: where the value came from.
/// - [isStale]: whether the caller should treat it as stale.
///
/// For example:
/// ```dart
/// if (result.isStale) {
///   refreshInBackground();
/// }
/// ```
///
/// {@category cache}

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
