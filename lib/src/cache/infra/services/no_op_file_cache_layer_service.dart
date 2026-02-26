import 'dart:typed_data';

import 'package:grumpy/grumpy.dart';

/// No-op file cache layer service.
class NoOpFileCacheLayerService extends FileCacheLayerService {
  /// No-op file cache layer service.
  const NoOpFileCacheLayerService() : super.internal();

  @override
  Future<void> destroy() async {}

  @override
  String get logTag => 'NoOpFileCacheLayerService';

  @override
  Future<void> clearNamespace(String namespace) async {
    log(
      'clearNamespace called on NoOpFileCacheLayerService for namespace: $namespace',
    );
  }

  @override
  Future<void> invalidate<T>(StorageKey key) async {
    log(
      'invalidate called on NoOpFileCacheLayerService for key: ${key.asStorageKey()}',
    );
  }

  @override
  Future<CacheEntry<T>?> read<T>(
    StorageKey key, {
    SerializationCodec<T, Uint8List>? codec,
  }) async {
    log(
      'read called on NoOpFileCacheLayerService for key: ${key.asStorageKey()}',
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
      'write called on NoOpFileCacheLayerService for key: ${key.asStorageKey()} with entry: $entry',
    );
  }
}
