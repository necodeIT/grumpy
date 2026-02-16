import 'package:grumpy/grumpy.dart';
import 'package:grumpy/src/infra/services/default_cache_pipeline_service.dart';
import 'package:grumpy/src/infra/services/memory_cache_layer_service.dart';
import 'package:test/test.dart';

void main() {
  test('pipeline reads memory hit', () async {
    final memory = InMemoryCacheLayerService();
    final pipeline = DefaultCachePipelineService(memoryLayer: memory);
    const key = _TestKey<String>('ns', 'k1');
    const policy = CachePolicy<Object>(useMemory: true);

    await pipeline.put<String, Object>(key, 'value', policy: policy);

    final result = await pipeline.get<String, Object>(key: key, policy: policy);

    expect(result, isNotNull);
    expect(result!.source, CacheSource.memory);
    expect(result.value, 'value');
  });
}

class _TestKey<T> implements CacheKey<T> {
  const _TestKey(this.namespace, this.primaryKey);

  @override
  final String namespace;

  @override
  final String primaryKey;

  @override
  String get schemaId => 's1';

  @override
  int? get compatVersion => null;

  @override
  String asStorageKey() => '$namespace|$schemaId|$primaryKey';
}
