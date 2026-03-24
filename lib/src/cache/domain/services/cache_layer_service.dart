import 'dart:typed_data';

import 'package:grumpy/grumpy.dart';

/// Shared cache layer surface.
///
/// Defines the minimum read/write/invalidation API for one cache layer.
///
/// The cache pipeline should be able to coordinate multiple storage backends
/// without knowing their concrete implementation details.
///
/// Implementations expose priority, key-based reads and writes, and namespace
/// invalidation operations.
///
/// Lower [priority] values are read earlier by the default pipeline.
///
/// - `T` on [read] and [write]: the runtime value type.
/// - [codec]: converts between runtime values and the layer's byte payload.
///
/// For example:
/// ```dart
/// final memory = MemoryCacheLayerService();
/// ```
///
/// {@category cache}

abstract class CacheLayerService extends Service {
  /// Returns the DI-registered implementation of [CacheLayerService].
  ///
  /// Shorthand for [Service.get].
  factory CacheLayerService() {
    return Service.get<CacheLayerService>();
  }

  /// Internal constructor for concrete layer implementations.
  const CacheLayerService.internal() : super();

  /// Layer ordering priority. Lower values are read earlier.
  int get priority;

  /// Reads a cached entry for [key], or `null` on miss.
  Future<CacheEntry<T>?> read<T>(
    StorageKey key, {

    /// Codec for serialized payload conversion.
    required SerializationCodec<T, Uint8List> codec,
  });

  /// Writes [entry] for [key].
  Future<void> write<T>(
    StorageKey key,
    CacheEntry<T> entry, {

    /// Codec for serialized payload conversion.
    required SerializationCodec<T, Uint8List> codec,
  });

  /// Invalidates a single key from this layer.
  Future<void> invalidate<T>(StorageKey key);

  /// Clears all entries under [namespace].
  Future<void> clearNamespace(String namespace);

  @override
  bool get singelton => true;
  @override
  String get group => '${super.group}.CacheLayerService';
}
