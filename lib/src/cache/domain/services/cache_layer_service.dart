import 'dart:typed_data';

import 'package:grumpy/grumpy.dart';

/// Shared cache layer surface.
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
