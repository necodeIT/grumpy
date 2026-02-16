import 'package:memory_cache/memory_cache.dart';
import 'package:grumpy/grumpy.dart';

/// Default in-memory cache layer implementation.
///
/// Notes:
/// - process-lifetime only (not persisted across restarts)
/// - stores [CacheEntry] objects directly (no serialization)
/// - key and namespace invalidation currently map to global clear because the
///   backing cache API does not expose targeted scans
class InMemoryCacheLayerService extends MemoryCacheLayerService {
  /// Creates an in-memory cache layer.
  InMemoryCacheLayerService() : super.internal();

  final MemoryCache _cache = MemoryCache();

  @override
  Future<CacheEntry<T>?> read<T, Serialized extends Object>(
    CacheKey<T> key, {
    SerializationCodec<T, Serialized>? codec,
  }) async {
    final stored = _cache.read<CacheEntry<T>>(key.asStorageKey());
    if (stored == null) return null;

    if (stored.isExpired) {
      _cache.invalidate();
      return null;
    }

    return stored;
  }

  @override
  Future<void> write<T, Serialized extends Object>(
    CacheKey<T> key,
    CacheEntry<T> entry, {
    SerializationCodec<T, Serialized>? codec,
  }) async {
    _cache.create(
      key.asStorageKey(),
      entry,
      expiry: entry.expiresAt?.difference(DateTime.now()),
    );
  }

  @override
  Future<void> invalidate<T>(CacheKey<T> key) async {
    _cache.invalidate();
  }

  @override
  Future<void> clearNamespace(String namespace) async {
    // MemoryCache does not expose namespace scans; invalidate-all is safest.
    _cache.invalidate();
  }

  @override
  Future<void> free() async {
    _cache.invalidate();
  }

  @override
  String get logTag => 'InMemoryCacheLayerService';
}
