import 'package:grumpy/grumpy.dart';

/// Per-query cache behavior.
///
/// [CachePolicy] controls how [CachePipelineService] reads/writes values across
/// layers for a single query execution.
///
/// Common profiles:
/// - Memory-only short-lived reads:
///   `CachePolicy(useMemory: true, useFile: false, memoryTtl: ...)`
/// - Durable reads across restarts:
///   `CachePolicy(useMemory: true, useFile: true, fileTtl: ...)`
/// - Strict debugging mode:
///   `CachePolicy(strictLayerErrors: true)`
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
