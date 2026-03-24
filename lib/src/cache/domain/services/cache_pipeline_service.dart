import 'dart:typed_data';

import 'package:grumpy/grumpy.dart';

/// Orchestrates multi-layer cache access.
///
/// Coordinates reads, writes, and invalidation across all configured cache
/// layers.
///
/// Query code should not need to manually orchestrate memory cache, file cache,
/// backfill, stale fallback, and error isolation.
///
/// The pipeline reads layers in priority order and applies [CachePolicy]
/// semantics such as write-through, backfill, strict errors, TTL split, and
/// stale metadata.
///
/// Repos usually reach this service indirectly through [QueryMixin].
///
/// - `T` on [get] and [put]: the runtime value type.
/// - [key], [policy], [codec]: the storage identity, behavior policy, and
///   serialization boundary for one cache operation.
///
/// For example:
/// ```dart
/// final pipeline = CachePipelineService();
/// ```
///
/// {@category cache}

abstract class CachePipelineService extends Service {
  /// Returns the DI-registered cache pipeline.
  factory CachePipelineService() => Service.get<CachePipelineService>();

  /// Internal constructor for concrete pipeline implementations.
  CachePipelineService.internal();

  /// Resolves a cache value for [key] according to [policy].
  ///
  /// Returns:
  /// - `CacheResult` when any enabled layer hits
  /// - `null` when all enabled layers miss
  ///
  /// [codec] is used when a layer stores serialized payloads.
  Future<CacheResult<T>?> get<T>({
    required StorageKey key,
    required CachePolicy<Uint8List> policy,

    /// Codec for serialized payload conversion.
    required SerializationCodec<T, Uint8List> codec,
  });

  /// Writes [value] for [key] according to [policy].
  ///
  /// Implementations should respect:
  /// - `writeThrough`
  /// - per-layer TTL values
  /// - `cacheNullResults`
  /// - strict vs isolated layer errors
  Future<void> put<T>(
    StorageKey key,
    T value, {
    required CachePolicy<Uint8List> policy,

    /// Codec for serialized payload conversion.
    required SerializationCodec<T, Uint8List> codec,
  });

  /// Invalidates [key] across all configured layers.
  Future<void> invalidate(StorageKey key);

  /// Clears [namespace] across all configured layers.
  Future<void> clearNamespace(String namespace);

  @override
  bool get singelton => true;

  @override
  String get group => '${super.group}.CachePipelineService';
}
