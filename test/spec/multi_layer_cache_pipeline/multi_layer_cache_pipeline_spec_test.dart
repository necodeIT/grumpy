import 'package:grumpy/grumpy.dart';
import 'package:grumpy/src/infra/services/default_cache_pipeline_service.dart';
import 'package:test/test.dart';

void main() {
  group('Spec: multi_layer_cache_pipeline', () {
    test('returns memory hit before reading file layer', () async {
      final memory = _MemoryLayer()
        ..readResult = CacheEntry<String>(
          value: 'from-memory',
          createdAt: DateTime.now(),
        );
      final file = _FileLayer()
        ..readResult = CacheEntry<String>(
          value: 'from-file',
          createdAt: DateTime.now(),
        );
      final pipeline = DefaultCachePipelineService(
        memoryLayer: memory,
        fileLayer: file,
      );

      final result = await pipeline.get<String, Object>(
        key: const _TestKey<String>('cache', 'hit'),
        policy: const CachePolicy<Object>(useMemory: true, useFile: true),
      );

      expect(
        result,
        isNotNull,
        reason:
            'Spec: multi_layer_cache_pipeline §6.2 requires read pipeline to return on first layer hit.',
      );
      expect(
        result!.source,
        CacheSource.memory,
        reason:
            'Spec: multi_layer_cache_pipeline §6.2 defines memory as the first read source.',
      );
      expect(
        result.value,
        'from-memory',
        reason:
            'Spec: multi_layer_cache_pipeline §6.2 expects value to come from the layer that hit first.',
      );
      expect(
        file.readCalls,
        0,
        reason:
            'Spec: multi_layer_cache_pipeline §6.2 short-circuits lower layers on upper-layer hit.',
      );
    });

    test('falls back to file layer and backfills memory when enabled', () async {
      final fileEntry = CacheEntry<String>(
        value: 'from-file',
        createdAt: DateTime.now(),
      );
      final memory = _MemoryLayer();
      final file = _FileLayer()..readResult = fileEntry;
      final pipeline = DefaultCachePipelineService(
        memoryLayer: memory,
        fileLayer: file,
      );

      final result = await pipeline.get<String, Object>(
        key: const _TestKey<String>('cache', 'fallback'),
        policy: const CachePolicy<Object>(
          useMemory: true,
          useFile: true,
          backfillHigherLayers: true,
        ),
      );

      expect(
        result,
        isNotNull,
        reason:
            'Spec: multi_layer_cache_pipeline §6.2 requires fallback to file when memory misses.',
      );
      expect(
        result!.source,
        CacheSource.file,
        reason:
            'Spec: multi_layer_cache_pipeline §6.2 classifies fallback hit source as file.',
      );
      expect(
        memory.writeCalls,
        1,
        reason:
            'Spec: multi_layer_cache_pipeline §6.2 and §6.3 require optional backfill to higher layers.',
      );
      expect(
        memory.lastWrittenEntry?.value,
        'from-file',
        reason:
            'Spec: multi_layer_cache_pipeline §6.2 requires backfill to store the value read from lower layer.',
      );
    });

    test('marks file result stale when file layer returns expired entry', () async {
      final memory = _MemoryLayer();
      final file = _FileLayer()
        ..readResult = CacheEntry<String>(
          value: 'stale',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );
      final pipeline = DefaultCachePipelineService(
        memoryLayer: memory,
        fileLayer: file,
      );

      final result = await pipeline.get<String, Object>(
        key: const _TestKey<String>('cache', 'stale'),
        policy: const CachePolicy<Object>(useMemory: true, useFile: true),
      );

      expect(
        result,
        isNotNull,
        reason:
            'Spec: multi_layer_cache_pipeline §2.5 and §6.2 require deterministic stale metadata handling.',
      );
      expect(
        result!.isStale,
        isTrue,
        reason:
            'Spec: multi_layer_cache_pipeline §6.2 includes stale-read behavior in read metadata.',
      );
    });

    test('swallows layer read errors in non-strict mode and continues', () async {
      final memory = _MemoryLayer()..readError = StateError('memory failed');
      final file = _FileLayer()
        ..readResult = CacheEntry<String>(
          value: 'from-file',
          createdAt: DateTime.now(),
        );
      final pipeline = DefaultCachePipelineService(
        memoryLayer: memory,
        fileLayer: file,
      );

      final result = await pipeline.get<String, Object>(
        key: const _TestKey<String>('cache', 'non-strict'),
        policy: const CachePolicy<Object>(
          useMemory: true,
          useFile: true,
          strictLayerErrors: false,
        ),
      );

      expect(
        result,
        isNotNull,
        reason:
            'Spec: multi_layer_cache_pipeline §6.3 states non-strict mode isolates layer failures.',
      );
      expect(
        result!.value,
        'from-file',
        reason:
            'Spec: multi_layer_cache_pipeline §6.2 requires fallback progression when upper layer fails.',
      );
    });

    test('propagates layer read errors in strict mode', () async {
      final memory = _MemoryLayer()..readError = StateError('memory failed');
      final pipeline = DefaultCachePipelineService(memoryLayer: memory);

      expect(
        () => pipeline.get<String, Object>(
          key: const _TestKey<String>('cache', 'strict'),
          policy: const CachePolicy<Object>(
            useMemory: true,
            strictLayerErrors: true,
          ),
        ),
        throwsA(isA<StateError>()),
        reason:
            'Spec: multi_layer_cache_pipeline §6.3 requires strict mode to bubble layer errors.',
      );
    });

    test('respects writeThrough=false and performs no writes', () async {
      final memory = _MemoryLayer();
      final file = _FileLayer();
      final pipeline = DefaultCachePipelineService(
        memoryLayer: memory,
        fileLayer: file,
      );

      await pipeline.put<String, Object>(
        const _TestKey<String>('cache', 'no-write-through'),
        'value',
        policy: const CachePolicy<Object>(
          useMemory: true,
          useFile: true,
          writeThrough: false,
        ),
      );

      expect(
        memory.writeCalls,
        0,
        reason:
            'Spec: multi_layer_cache_pipeline §6.3 makes write-through policy-driven and optional.',
      );
      expect(
        file.writeCalls,
        0,
        reason:
            'Spec: multi_layer_cache_pipeline §6.3 requires no layer writes when writeThrough is disabled.',
      );
    });

    test('does not cache null when cacheNullResults=false', () async {
      final memory = _MemoryLayer();
      final file = _FileLayer();
      final pipeline = DefaultCachePipelineService(
        memoryLayer: memory,
        fileLayer: file,
      );

      await pipeline.put<String?, Object>(
        const _TestKey<String?>('cache', 'null'),
        null,
        policy: const CachePolicy<Object>(
          useMemory: true,
          useFile: true,
          cacheNullResults: false,
        ),
      );

      expect(
        memory.writeCalls,
        0,
        reason:
            'Spec: multi_layer_cache_pipeline §7.2 requires null-caching to be explicitly policy-controlled.',
      );
      expect(
        file.writeCalls,
        0,
        reason:
            'Spec: multi_layer_cache_pipeline §7.2 requires no persistence for null when disabled.',
      );
    });

    test('applies layer-specific TTLs on write-through', () async {
      final memory = _MemoryLayer();
      final file = _FileLayer();
      final pipeline = DefaultCachePipelineService(
        memoryLayer: memory,
        fileLayer: file,
      );

      await pipeline.put<String, Object>(
        const _TestKey<String>('cache', 'ttl'),
        'value',
        policy: const CachePolicy<Object>(
          useMemory: true,
          useFile: true,
          memoryTtl: Duration(seconds: 20),
          fileTtl: Duration(seconds: 90),
        ),
      );

      final memoryDelta = memory.lastWrittenEntry!.expiresAt!.difference(
        memory.lastWrittenEntry!.createdAt,
      );
      final fileDelta = file.lastWrittenEntry!.expiresAt!.difference(
        file.lastWrittenEntry!.createdAt,
      );
      expect(
        memoryDelta.inSeconds,
        20,
        reason:
            'Spec: multi_layer_cache_pipeline §7.2 defines per-layer TTL controls.',
      );
      expect(
        fileDelta.inSeconds,
        90,
        reason:
            'Spec: multi_layer_cache_pipeline §7.2 requires independent file-layer TTL behavior.',
      );
    });

    test('invalidates key in both layers', () async {
      final memory = _MemoryLayer();
      final file = _FileLayer();
      final key = const _TestKey<String>('cache', 'invalidate');
      final pipeline = DefaultCachePipelineService(
        memoryLayer: memory,
        fileLayer: file,
      );

      await pipeline.invalidate<String>(key);

      expect(
        memory.invalidatedKeys,
        contains(key.asStorageKey()),
        reason:
            'Spec: multi_layer_cache_pipeline §6.3 requires key invalidation across enabled layers.',
      );
      expect(
        file.invalidatedKeys,
        contains(key.asStorageKey()),
        reason:
            'Spec: multi_layer_cache_pipeline §6.3 requires file-layer invalidation in the same pipeline call.',
      );
    });

    test('clears namespace in both layers', () async {
      final memory = _MemoryLayer();
      final file = _FileLayer();
      final pipeline = DefaultCachePipelineService(
        memoryLayer: memory,
        fileLayer: file,
      );

      await pipeline.clearNamespace('users');

      expect(
        memory.clearedNamespaces,
        contains('users'),
        reason:
            'Spec: multi_layer_cache_pipeline §6.3 requires namespace-level invalidation hooks.',
      );
      expect(
        file.clearedNamespaces,
        contains('users'),
        reason:
            'Spec: multi_layer_cache_pipeline §6.3 requires coordinated namespace clear across layers.',
      );
    });
  });
}

class _MemoryLayer extends MemoryCacheLayerService {
  _MemoryLayer() : super.internal();

  CacheEntry<Object?>? readResult;
  Object? readError;
  Object? writeError;
  int readCalls = 0;
  int writeCalls = 0;
  CacheEntry<Object?>? lastWrittenEntry;
  final List<String> invalidatedKeys = <String>[];
  final List<String> clearedNamespaces = <String>[];

  @override
  Future<CacheEntry<T>?> read<T, Serialized extends Object>(
    CacheKey<T> key, {
    SerializationCodec<T, Serialized>? codec,
  }) async {
    readCalls++;
    if (readError != null) throw readError!;
    return readResult as CacheEntry<T>?;
  }

  @override
  Future<void> write<T, Serialized extends Object>(
    CacheKey<T> key,
    CacheEntry<T> entry, {
    SerializationCodec<T, Serialized>? codec,
  }) async {
    writeCalls++;
    if (writeError != null) throw writeError!;
    lastWrittenEntry = entry as CacheEntry<Object?>;
  }

  @override
  Future<void> invalidate<T>(CacheKey<T> key) async {
    invalidatedKeys.add(key.asStorageKey());
  }

  @override
  Future<void> clearNamespace(String namespace) async {
    clearedNamespaces.add(namespace);
  }

  @override
  Future<void> free() async {}

  @override
  String get logTag => '_MemoryLayer';
}

class _FileLayer extends FileCacheLayerService {
  _FileLayer() : super.internal();

  CacheEntry<Object?>? readResult;
  Object? readError;
  Object? writeError;
  int readCalls = 0;
  int writeCalls = 0;
  CacheEntry<Object?>? lastWrittenEntry;
  final List<String> invalidatedKeys = <String>[];
  final List<String> clearedNamespaces = <String>[];

  @override
  Future<CacheEntry<T>?> read<T, Serialized extends Object>(
    CacheKey<T> key, {
    SerializationCodec<T, Serialized>? codec,
  }) async {
    readCalls++;
    if (readError != null) throw readError!;
    return readResult as CacheEntry<T>?;
  }

  @override
  Future<void> write<T, Serialized extends Object>(
    CacheKey<T> key,
    CacheEntry<T> entry, {
    SerializationCodec<T, Serialized>? codec,
  }) async {
    writeCalls++;
    if (writeError != null) throw writeError!;
    lastWrittenEntry = entry as CacheEntry<Object?>;
  }

  @override
  Future<void> invalidate<T>(CacheKey<T> key) async {
    invalidatedKeys.add(key.asStorageKey());
  }

  @override
  Future<void> clearNamespace(String namespace) async {
    clearedNamespaces.add(namespace);
  }

  @override
  Future<void> free() async {}

  @override
  String get logTag => '_FileLayer';
}

class _TestKey<T> implements CacheKey<T> {
  const _TestKey(this.namespace, this.primaryKey);

  @override
  final String namespace;

  @override
  final String primaryKey;

  @override
  String get schemaId => 'cache-schema-v1';

  @override
  int? get compatVersion => null;

  @override
  String asStorageKey() => '$namespace|$schemaId|$primaryKey';
}
