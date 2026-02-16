import 'package:grumpy/grumpy.dart';

/// Shared cache layer surface.
abstract class CacheLayerService extends Service {
  /// Returns the DI-registered implementation of [CacheLayerService].
  ///
  /// Shorthand for [Service.get].
  factory CacheLayerService() {
    return Service.get<CacheLayerService>();
  }

  /// Internal constructor for concrete layer implementations.
  CacheLayerService.internal() : super();

  /// Layer ordering priority. Lower values are read earlier.
  int get priority;

  /// Reads a cached entry for [key], or `null` on miss.
  Future<CacheEntry<T>?> read<T, Serialized extends Object>(
    CacheKey<T> key, {

    /// Optional codec for serialized payload conversion.
    SerializationCodec<T, Serialized>? codec,
  });

  /// Writes [entry] for [key].
  Future<void> write<T, Serialized extends Object>(
    CacheKey<T> key,
    CacheEntry<T> entry, {

    /// Optional codec for serialized payload conversion.
    SerializationCodec<T, Serialized>? codec,
  });

  /// Invalidates a single key from this layer.
  Future<void> invalidate<T>(CacheKey<T> key);

  /// Clears all entries under [namespace].
  Future<void> clearNamespace(String namespace);

  @override
  bool get singelton => true;
  @override
  String get group => '${super.group}.CacheLayerService';
}
