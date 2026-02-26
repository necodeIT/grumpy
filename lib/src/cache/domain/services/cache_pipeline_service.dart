import 'dart:typed_data';

import 'package:grumpy/grumpy.dart';

/// Orchestrates multi-layer cache access.
///
/// The pipeline is responsible for ordered layer reads/writes and for applying
/// [CachePolicy] semantics (write-through, backfill, strict errors, TTL split,
/// stale metadata).
///
/// Repos typically do not call this service directly. Prefer [QueryMixin],
/// which integrates this pipeline automatically when registered.
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

    /// Optional codec for serialized payload conversion.
    SerializationCodec<T, Uint8List>? codec,
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

    /// Optional codec for serialized payload conversion.
    SerializationCodec<T, Uint8List>? codec,
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
