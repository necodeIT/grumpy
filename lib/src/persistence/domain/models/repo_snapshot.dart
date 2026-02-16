import 'package:grumpy/grumpy.dart';

/// Persisted repo state envelope.
class RepoSnapshot<T> extends Model {
  /// Creates a serialized repo snapshot envelope.
  const RepoSnapshot({
    /// Canonical repo data payload.
    required this.data,

    /// Timestamp when the snapshot was written.
    required this.savedAt,

    /// Optional expiration timestamp.
    this.expiresAt,

    /// Optional timestamp of last successful sync.
    this.lastSyncAt,

    /// Extra metadata persisted alongside snapshot data.
    this.metadata = const {},
  });

  /// Canonical repo data payload.
  final T data;

  /// Timestamp when the snapshot was written.
  final DateTime savedAt;

  /// Optional expiration timestamp.
  final DateTime? expiresAt;

  /// Optional timestamp of last successful sync.
  final DateTime? lastSyncAt;

  /// Extra metadata persisted alongside snapshot data.
  final Map<String, Object?> metadata;

  /// Returns `true` when this snapshot is expired at read time.
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}
