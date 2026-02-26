import 'dart:typed_data';

import 'package:grumpy/grumpy.dart';

/// No-op memory cache layer service.
class NoOpMemoryCacheLayerService extends MemoryCacheLayerService {
  /// No-op memory cache layer service.
  const NoOpMemoryCacheLayerService() : super.internal();

  @override
  Future<void> destroy() async {}

  @override
  String get logTag => 'NoOpMemoryCacheLayerService';

  @override
  Future<void> clearNamespace(String namespace) async {
    log(
      'clearNamespace called on NoOpMemoryCacheLayerService for namespace: $namespace',
    );
  }

  @override
  Future<void> invalidate<T>(StorageKey key) async {
    log(
      'invalidate called on NoOpMemoryCacheLayerService for key: ${key.asStorageKey()}',
    );
  }

  @override
  Future<CacheEntry<T>?> read<T>(
    StorageKey key, {
    SerializationCodec<T, Uint8List>? codec,
  }) async {
    log(
      'read called on NoOpMemoryCacheLayerService for key: ${key.asStorageKey()}',
    );
    return null;
  }

  @override
  Future<void> write<T>(
    StorageKey key,
    CacheEntry<T> entry, {
    SerializationCodec<T, Uint8List>? codec,
  }) async {
    log(
      'write called on NoOpMemoryCacheLayerService for key: ${key.asStorageKey()} with entry: $entry',
    );
  }
}
