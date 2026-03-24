import 'package:grumpy/grumpy.dart';

/// Per-query cache behavior.
///
/// Describes how one query should interact with the cache pipeline.
///
/// Different reads need different durability, TTL, backfill, and stale-fallback
/// behavior.
///
/// [CachePolicy] enables or disables layers and controls write-through,
/// backfill, TTLs, strict errors, null caching, and schema mismatch handling.
///
/// This policy is evaluated per query call, not as a global cache setting.
///
/// - `Serialized`: the serialized payload type used by mismatch handling.
/// - [useMemory], [useFile]: enable cache layers.
/// - [memoryTtl], [fileTtl]: freshness windows per layer.
/// - [writeThrough], [backfillHigherLayers]: write behavior.
/// - [allowStaleFileOnQueryError], [strictLayerErrors], [cacheNullResults]:
///   error and fallback controls.
///
/// For example:
/// ```dart
/// const CachePolicy<Uint8List>(
///   useMemory: true,
///   useFile: true,
///   fileTtl: Duration(hours: 1),
/// );
/// ```
///
/// {@category cache}

class CachePolicy<Serialized extends Object> extends Model {
  /// Creates cache behavior options for a query read/write cycle.
  const CachePolicy({
    /// Enables reads/writes against the memory layer.
    this.useMemory = true,

    /// Enables reads/writes against the file layer.
    this.useFile = false,

    /// Optional memory-layer TTL.
    this.memoryTtl,

    /// Optional file-layer TTL.
    this.fileTtl,

    /// Returns stale file value when query execution fails.
    ///
    /// This only applies when file layer returns a stale value and query
    /// callback throws.
    this.allowStaleFileOnQueryError = true,

    /// Writes successful query results back into enabled layers.
    this.writeThrough = true,

    /// Writes lower-layer hits back into higher-priority layers.
    this.backfillHigherLayers = true,

    /// Persists `null` query results when enabled.
    this.cacheNullResults = true,

    /// Throws immediately on layer errors when enabled.
    this.strictLayerErrors = false,

    /// Custom schema mismatch resolver for serialized payloads.
    this.onSchemaMismatch,
  });

  /// Enables reads/writes against the memory layer.
  final bool useMemory;

  /// Enables reads/writes against the file layer.
  final bool useFile;

  /// Optional memory-layer TTL.
  final Duration? memoryTtl;

  /// Optional file-layer TTL.
  final Duration? fileTtl;

  /// Returns stale file value when query execution fails.
  final bool allowStaleFileOnQueryError;

  /// Writes successful query results back into enabled layers.
  final bool writeThrough;

  /// Writes lower-layer hits back into higher-priority layers.
  final bool backfillHigherLayers;

  /// Persists `null` query results when enabled.
  final bool cacheNullResults;

  /// Throws immediately on layer errors when enabled.
  final bool strictLayerErrors;

  /// Custom schema mismatch resolver for serialized payloads.
  final SchemaMismatchResolver<Serialized>? onSchemaMismatch;
}
