import 'package:grumpy/grumpy.dart';

/// Stored cache entry with optional expiry metadata.
///
/// Wraps a cached value together with the timestamps and metadata needed to
/// reason about freshness.
///
/// Cache layers need more than just the raw value in order to support TTLs,
/// stale reads, and validator metadata such as ETags.
///
/// The entry stores the cached value, creation time, optional absolute expiry,
/// and optional [etag].
///
/// [isExpired] is evaluated against `DateTime.now()`, so it reflects read time,
/// not write time.
///
/// - `T`: the runtime value type.
/// - [createdAt], [expiresAt], [etag]: freshness and validation metadata.
///
/// For example:
/// ```dart
/// final entry = CacheEntry(
///   value: user,
///   createdAt: DateTime.now(),
/// );
/// ```
///
/// {@category cache}

class CacheEntry<T> extends Model {
  /// Creates a cache entry.
  const CacheEntry({
    /// Cached runtime value.
    required this.value,

    /// Entry creation timestamp.
    required this.createdAt,

    /// Optional absolute expiration timestamp.
    this.expiresAt,

    /// Optional entity tag/version.
    this.etag,
  });

  /// Cached runtime value.
  final T value;

  /// Entry creation timestamp.
  final DateTime createdAt;

  /// Optional absolute expiration timestamp.
  final DateTime? expiresAt;

  /// Optional entity tag/version.
  final String? etag;

  /// Returns `true` when this entry is expired at read time.
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}
