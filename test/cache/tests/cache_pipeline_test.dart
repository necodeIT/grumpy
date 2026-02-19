import 'package:grumpy/grumpy.dart';
import 'package:grumpy/src/cache/infra/services/default_cache_pipeline_service.dart';
import 'package:grumpy/src/cache/infra/services/memory_cache_layer_service.dart';
import 'package:test/test.dart';
import '../harness/cache_pipeline_test_harness.dart';
import '../harness/harness.dart';

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
        memoryLayer: ThrowingMemoryBackfillLayer(),
        fileLayer: SeededFileLayer(
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
          memoryLayer: StaticMemoryLayer(
            CacheEntry<String>(value: 'memory', createdAt: DateTime.now()),
            priority: 99,
          ),
          fileLayer: StaticFileLayer(
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
