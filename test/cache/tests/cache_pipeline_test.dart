import 'package:grumpy/grumpy.dart';
import 'package:grumpy/src/cache/infra/services/default_cache_pipeline_service.dart';
import 'package:grumpy/src/cache/infra/services/memory_cache_layer_service.dart';
import 'package:test/test.dart';
import '../harness/cache_pipeline_test_harness.dart';

void main() {
  test('pipeline reads memory hit', () async {
    final memory = InMemoryCacheLayerService();
    final pipeline = DefaultCachePipelineService(memoryLayer: memory);
    const key = TestKey<String>('ns', 'k1');
    const policy = CachePolicy<Object>(useMemory: true);

    await pipeline.put<String, Object>(key, 'value', policy: policy);

    final result = await pipeline.get<String, Object>(key: key, policy: policy);

    expect(result, isNotNull);
    expect(result!.source, CacheSource.memory);
    expect(result.value, 'value');
  });

  group('Issue coverage: backfill and strict error policy', () {
    test('non-strict reads isolate memory backfill write failures', () async {
      final pipeline = DefaultCachePipelineService(
        memoryLayer: _ThrowingMemoryBackfillLayer(),
        fileLayer: _SeededFileLayer(
          CacheEntry<String>(value: 'from-file', createdAt: DateTime.now()),
        ),
      );
      const key = TestKey<String>('ns', 'k2');
      const policy = CachePolicy<Object>(
        useMemory: true,
        useFile: true,
        strictLayerErrors: false,
        backfillHigherLayers: true,
      );

      final result = await pipeline.get<String, Object>(
        key: key,
        policy: policy,
      );

      expect(result, isNotNull);
      expect(result!.source, CacheSource.file);
      expect(result.value, 'from-file');
    });
  });

  group('Issue coverage: layer priority contract', () {
    test(
      'respects layer priority ordering when selecting read source',
      () async {
        final pipeline = DefaultCachePipelineService(
          memoryLayer: _StaticMemoryLayer(
            CacheEntry<String>(value: 'memory', createdAt: DateTime.now()),
            priority: 99,
          ),
          fileLayer: _StaticFileLayer(
            CacheEntry<String>(value: 'file', createdAt: DateTime.now()),
            priority: -1,
          ),
        );
        const key = TestKey<String>('ns', 'k3');
        const policy = CachePolicy<Object>(useMemory: true, useFile: true);

        final result = await pipeline.get<String, Object>(
          key: key,
          policy: policy,
        );

        expect(result, isNotNull);
        expect(result!.source, CacheSource.file);
        expect(result.value, 'file');
      },
    );
  });
}

class _ThrowingMemoryBackfillLayer extends MemoryCacheLayerService {
  _ThrowingMemoryBackfillLayer() : super.internal();

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
  String get logTag => '_ThrowingMemoryBackfillLayer';
}

class _SeededFileLayer extends FileCacheLayerService {
  _SeededFileLayer(this.entry) : super.internal();

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
  String get logTag => '_SeededFileLayer';
}

class _StaticMemoryLayer extends MemoryCacheLayerService {
  _StaticMemoryLayer(this.entry, {required this.priority}) : super.internal();

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
  String get logTag => '_StaticMemoryLayer';
}

class _StaticFileLayer extends FileCacheLayerService {
  _StaticFileLayer(this.entry, {required this.priority}) : super.internal();

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
  String get logTag => '_StaticFileLayer';
}
