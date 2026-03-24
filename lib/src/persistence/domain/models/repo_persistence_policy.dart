import 'package:grumpy/grumpy.dart';

/// Repo snapshot persistence controls.
///
/// Configures when and how repo snapshots are written or deleted.
///
/// Different repos need different durability guarantees and write amplification
/// tradeoffs.
///
/// [RepoPersistencePolicy] controls enablement, debounce, TTL, corruption
/// handling, null persistence, and schema mismatch resolution.
///
/// Persistence is off by default and must be enabled per repo.
///
/// - `Serialized`: the serialized snapshot payload type.
/// - [enabled], [snapshotTtl], [persistDebounce]: write behavior.
/// - [deleteOnCorruption], [saveNullData], [onSchemaMismatch]: error handling.
///
/// For example:
/// ```dart
/// const RepoPersistencePolicy<Uint8List>(
///   enabled: true,
///   snapshotTtl: Duration(hours: 12),
/// );
/// ```
///
/// {@category persistence}

class RepoPersistencePolicy<Serialized extends Object> extends Model {
  /// Creates repo snapshot persistence options.
  const RepoPersistencePolicy({
    /// Enables snapshot persistence.
    this.enabled = false,

    /// Optional snapshot expiration window.
    this.snapshotTtl,

    /// Persists when repo emits new data.
    this.persistOnData = true,

    /// Debounce window before snapshot save.
    this.persistDebounce = const Duration(milliseconds: 300),

    /// Deletes corrupted snapshots when detected.
    this.deleteOnCorruption = true,

    /// Persists null data values when enabled.
    this.saveNullData = false,

    /// Custom schema mismatch resolver for snapshot payloads.
    this.onSchemaMismatch,
  });

  /// Enables snapshot persistence.
  final bool enabled;

  /// Optional snapshot expiration window.
  final Duration? snapshotTtl;

  /// Persists when repo emits new data.
  final bool persistOnData;

  /// Debounce window before snapshot save.
  final Duration persistDebounce;

  /// Deletes corrupted snapshots when detected.
  final bool deleteOnCorruption;

  /// Persists null data values when enabled.
  final bool saveNullData;

  /// Custom schema mismatch resolver for snapshot payloads.
  final SchemaMismatchResolver<Serialized>? onSchemaMismatch;
}
