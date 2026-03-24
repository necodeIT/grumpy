# Cache

`cache` defines read-path caching contracts, policies, and multi-layer pipeline behavior for repo queries. It exists so repos can stay focused on domain reads while TTLs, stale-data handling, backfill, and multi-layer storage concerns live in one place.

The feature works through a small set of cooperating types: `CacheLayerService` abstracts one layer, `CachePipelineService` reads and writes layers in priority order, `QueryMixin` builds `StorageKey` instances and deduplicates concurrent reads, and `CachePolicy` controls TTLs, stale fallback, write-through, strict error behavior, and backfill on a per-query basis.

The main thing to keep in mind is that public cache keys are `StorageKey`, not `CacheKey`, and pipeline caching is opt-in through `QueryMixin.enableCachePipeline`. `StorageKey` carries namespace, primary key, and schema identity, `CachePolicy` carries the behavioral switches, and `SerializationCodec<T, Uint8List>` is required whenever cached values cross a byte boundary. If a repo uses `QueryMixin`, it still needs `installMemoryCacheHooks()` in the constructor.

For example:

```dart
return query<User?>(
  'userById',
  (users) => users.firstWhere((user) => user.id == id),
  queryParams: {'id': id},
  cachePolicy: const CachePolicy<Uint8List>(useMemory: true, useFile: true),
  codec: userCodec,
);
```
