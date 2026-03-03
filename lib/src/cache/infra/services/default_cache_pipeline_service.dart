import 'dart:typed_data';

import 'package:grumpy/grumpy.dart';

/// Default cache pipeline implementation.
///
/// Read order:
/// 1. memory layer (if enabled)
/// 2. file layer (if enabled)
///
/// Write behavior:
/// - write-through to enabled layers when policy allows
/// - per-layer TTL application
/// - optional strict error propagation
///
/// {@category cache}

class DefaultCachePipelineService extends CachePipelineService {
  /// Creates a default pipeline with optional memory/file layers.
  DefaultCachePipelineService({
    MemoryCacheLayerService? memoryLayer,
    FileCacheLayerService? fileLayer,
  }) : _memoryLayer = memoryLayer,
       _fileLayer = fileLayer,
       super.internal();

  final MemoryCacheLayerService? _memoryLayer;
  final FileCacheLayerService? _fileLayer;

  /// Attempts layered cache read according to [policy].
  ///
  /// Returns `null` when no enabled layer contains data.
  @override
  Future<CacheResult<T>?> get<T>({
    required StorageKey key,
    required CachePolicy<Uint8List> policy,
    SerializationCodec<T, Uint8List>? codec,
  }) async {
    final layers =
        <
          ({
            CacheSource source,
            int priority,
            Future<CacheEntry<T>?> Function() read,
            Future<void> Function(CacheEntry<T> entry) write,
          })
        >[];

    if (policy.useMemory && _memoryLayer != null) {
      layers.add((
        source: CacheSource.memory,
        priority: _memoryLayer.priority,
        read: () => _memoryLayer.read<T>(key, codec: codec),
        write: (entry) => _memoryLayer.write<T>(key, entry, codec: codec),
      ));
    }

    if (policy.useFile && _fileLayer != null) {
      layers.add((
        source: CacheSource.file,
        priority: _fileLayer.priority,
        read: () => _fileLayer.read<T>(key, codec: codec),
        write: (entry) => _fileLayer.write<T>(key, entry, codec: codec),
      ));
    }

    layers.sort((a, b) => a.priority.compareTo(b.priority));

    for (final layer in layers) {
      CacheEntry<T>? entry;
      try {
        entry = await layer.read();
      } catch (e) {
        if (policy.strictLayerErrors) rethrow;
        log(
          '${layer.source == CacheSource.memory ? 'Memory' : 'File'} layer read failed for ${key.asStorageKey()}',
          e,
        );
        continue;
      }

      if (entry == null) continue;

      if (policy.backfillHigherLayers) {
        for (final higherLayer in layers) {
          if (higherLayer.priority >= layer.priority) continue;

          try {
            await higherLayer.write(entry);
          } catch (e) {
            if (policy.strictLayerErrors) rethrow;
            log(
              '${higherLayer.source == CacheSource.memory ? 'Memory' : 'File'} layer backfill failed for ${key.asStorageKey()}',
              e,
            );
          }
        }
      }

      return CacheResult<T>(
        value: entry.value,
        source: layer.source,
        isStale: layer.source == CacheSource.file ? entry.isExpired : false,
      );
    }

    return null;
  }

  /// Performs write-through to configured layers according to [policy].
  @override
  Future<void> put<T>(
    StorageKey key,
    T value, {
    required CachePolicy<Uint8List> policy,
    SerializationCodec<T, Uint8List>? codec,
  }) async {
    if (!policy.writeThrough) return;
    if (!policy.cacheNullResults && value == null) return;

    final now = DateTime.now();

    if (policy.useMemory && _memoryLayer != null) {
      final entry = CacheEntry<T>(
        value: value,
        createdAt: now,
        expiresAt: policy.memoryTtl == null ? null : now.add(policy.memoryTtl!),
      );
      try {
        await _memoryLayer.write<T>(key, entry, codec: codec);
      } catch (e) {
        if (policy.strictLayerErrors) rethrow;
        log('Memory layer write failed for ${key.asStorageKey()}', e);
      }
    }

    if (policy.useFile && _fileLayer != null) {
      final entry = CacheEntry<T>(
        value: value,
        createdAt: now,
        expiresAt: policy.fileTtl == null ? null : now.add(policy.fileTtl!),
      );
      try {
        await _fileLayer.write<T>(key, entry, codec: codec);
      } catch (e) {
        if (policy.strictLayerErrors) rethrow;
        log('File layer write failed for ${key.asStorageKey()}', e);
      }
    }
  }

  @override
  Future<void> invalidate(StorageKey key) async {
    await Future.wait([
      if (_memoryLayer != null) _memoryLayer.invalidate(key),
      if (_fileLayer != null) _fileLayer.invalidate(key),
    ]);
  }

  @override
  Future<void> clearNamespace(String namespace) async {
    await Future.wait([
      if (_memoryLayer != null) _memoryLayer.clearNamespace(namespace),
      if (_fileLayer != null) _fileLayer.clearNamespace(namespace),
    ]);
  }

  @override
  Future<void> destroy() async {}

  @override
  String get logTag => 'DefaultCachePipelineService';
}
