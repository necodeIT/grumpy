import 'package:grumpy/grumpy.dart';

/// Stored cache entry with optional expiry metadata.
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
