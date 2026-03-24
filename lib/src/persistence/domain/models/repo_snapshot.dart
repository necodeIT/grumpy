import 'package:grumpy/grumpy.dart';

/// Persisted repo state envelope.
///
/// Wraps repo data together with timestamps and persistence metadata.
///
/// Snapshot storage needs more context than the raw repo payload in order to
/// support expiry, sync tracking, and migrations.
///
/// [RepoSnapshot] stores the data plus save time, optional expiry,
/// optional sync time, and arbitrary metadata.
///
/// [isExpired] is evaluated at read time against `DateTime.now()`.
///
/// - `T`: the repo data type being persisted.
/// - [savedAt], [expiresAt], [lastSyncAt], [metadata]: persistence metadata.
///
/// For example:
/// ```dart
/// final snapshot = RepoSnapshot(
///   data: state,
///   savedAt: DateTime.now(),
/// );
/// ```
///
/// {@category persistence}

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
