export '../../shared/harness/harness.dart' show TestKey;
import 'package:grumpy/grumpy.dart';

class StaticFileLayer extends FileCacheLayerService {
  StaticFileLayer(this.entry, {required this.priority}) : super.internal();

  final CacheEntry<Object?>? entry;

  @override
  final int priority;

  @override
  Future<CacheEntry<T>?> read<T, Serialized extends Object>(
    CacheKey<T> key, {
    SerializationCodec<T, Serialized>? codec,
  }) async => entry as CacheEntry<T>?;

  @override
  Future<void> write<T, Serialized extends Object>(
    CacheKey<T> key,
    CacheEntry<T> entry, {
    SerializationCodec<T, Serialized>? codec,
  }) async {}

  @override
  Future<void> invalidate<T>(CacheKey<T> key) async {}

  @override
  Future<void> clearNamespace(String namespace) async {}

  @override
  Future<void> free() async {}

  @override
  String get logTag => 'StaticFileLayer';
}

class ThrowingMemoryBackfillLayer extends MemoryCacheLayerService {
  ThrowingMemoryBackfillLayer() : super.internal();

  @override
  Future<CacheEntry<T>?> read<T, Serialized extends Object>(
    CacheKey<T> key, {
    SerializationCodec<T, Serialized>? codec,
  }) async => null;

  @override
  Future<void> write<T, Serialized extends Object>(
    CacheKey<T> key,
    CacheEntry<T> entry, {
    SerializationCodec<T, Serialized>? codec,
  }) async {
    throw StateError('synthetic memory backfill write failure');
  }

  @override
  Future<void> invalidate<T>(CacheKey<T> key) async {}

  @override
  Future<void> clearNamespace(String namespace) async {}

  @override
  Future<void> free() async {}

  @override
  String get logTag => 'ThrowingMemoryBackfillLayer';
}

class SeededFileLayer extends FileCacheLayerService {
  SeededFileLayer(this.entry) : super.internal();

  final CacheEntry<Object?>? entry;

  @override
  Future<CacheEntry<T>?> read<T, Serialized extends Object>(
    CacheKey<T> key, {
    SerializationCodec<T, Serialized>? codec,
  }) async => entry as CacheEntry<T>?;

  @override
  Future<void> write<T, Serialized extends Object>(
    CacheKey<T> key,
    CacheEntry<T> entry, {
    SerializationCodec<T, Serialized>? codec,
  }) async {}

  @override
  Future<void> invalidate<T>(CacheKey<T> key) async {}

  @override
  Future<void> clearNamespace(String namespace) async {}

  @override
  Future<void> free() async {}

  @override
  String get logTag => 'SeededFileLayer';
}

class StaticMemoryLayer extends MemoryCacheLayerService {
  StaticMemoryLayer(this.entry, {required this.priority}) : super.internal();

  final CacheEntry<Object?>? entry;

  @override
  final int priority;

  @override
  Future<CacheEntry<T>?> read<T, Serialized extends Object>(
    CacheKey<T> key, {
    SerializationCodec<T, Serialized>? codec,
  }) async => entry as CacheEntry<T>?;

  @override
  Future<void> write<T, Serialized extends Object>(
    CacheKey<T> key,
    CacheEntry<T> entry, {
    SerializationCodec<T, Serialized>? codec,
  }) async {}

  @override
  Future<void> invalidate<T>(CacheKey<T> key) async {}

  @override
  Future<void> clearNamespace(String namespace) async {}

  @override
  Future<void> free() async {}

  @override
  String get logTag => 'StaticMemoryLayer';
}
