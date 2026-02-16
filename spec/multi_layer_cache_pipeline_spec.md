# Multi-Layer Cache Pipeline Spec

Status: Implemented
Owner: grumpy runtime
Target: query/read-path caching across memory and file storage, with query execution on cache miss

## 1. Problem Statement

Current query caching is implemented directly in `QueryMixin` with an in-memory cache only.
This works for short-lived lookups, but it does not provide:

- durable cache across app restarts (file/persistent storage)
- staged fallback behavior (memory -> file -> query execution)
- consistent layer-specific TTL and invalidation policy
- configurable opt-in per module/repo/query
- robust override points for apps with custom storage/network requirements

The architecture already supports DI-based service overrides (`RootModule` builders), so cache behavior should be elevated into first-class services rather than remaining hardcoded in a mixin.

## 2. Goals

1. Support layered cache reads with ordered fallback:
   - L1 memory cache
   - L2 file/persistent cache
2. Keep caching fully opt-in and non-breaking for existing repos.
3. Allow overrides at multiple levels:
   - app/root defaults
   - module-level bindings
   - repo-level defaults
   - per-query call overrides
4. Preserve existing telemetry and analytics integration style.
5. Ensure deterministic behavior under errors, stale data, and concurrent reads.
6. Keep API generic so one shared cache pipeline can serve many model types.
7. Ensure `QueryMixin` remains the execution boundary: on miss, run query code and hydrate cache.

## 3. Non-Goals

1. Writing a complete offline-sync engine with bidirectional reconciliation.
2. Introducing global cross-repo transactional cache invalidation in v1.
3. Requiring one cache service per model type.
4. Replacing domain-specific repositories with a generic key/value API.

## 4. Current State Summary

Relevant current implementation:

- `QueryMixin` has built-in `MemoryCache` usage and key/version behavior.
- Cache invalidation hooks are installed via `RepoLifecycleHooksMixin`.
- Root-level services are already injectable and overridable via `RootModule` builders.

Implication:

- The migration path should preserve `QueryMixin` ergonomics while delegating storage/fallback logic into services.
- Shared storage/serialization/schema contracts are defined in
  `spec/shared_storage_serialization_foundation_spec.md` and reused here.

## 5. Architectural Decision

Adopt a **policy-driven cache pipeline**:

- layer services own concrete read/write/invalidate behavior
- a pipeline service orchestrates ordered reads and write-through/backfill
- repos/mixins submit cache requests with policy and key metadata

This keeps infrastructure concerns in services and leaves repos focused on domain queries.

## 6. High-Level Model

### 6.1 Concepts

1. `StorageKey`
   - shared contract that enforces `asStorageKey()` across key types
2. `CacheKey<T>`
   - typed key contract for a cached query result
   - includes namespace + logical key parts
   - includes auto-generated schema fingerprint and optional compatibility version
3. `CachePolicy`
   - enables/disables layers
   - defines TTLs and backfill behavior
   - controls stale-read fallback and refresh mode
4. `CacheLayerService`
   - overarching shared contract for cache layers
5. `MemoryCacheLayerService`
   - typed L1 memory-layer contract
6. `FileCacheLayerService`
   - typed L2 file-layer contract
7. `CachePipelineService`
   - orchestrates multi-layer cache read/write/invalidate (memory + file)
8. `SerializationCodec<Data, Serialized>`
   - shared serialization contract used by both query cache and repo snapshot persistence
   - strongly typed wire format (`Serialized`) instead of untyped `Object?`

### 6.2 Read Flow (default)

1. Attempt L1 memory (if enabled).
2. On miss, attempt L2 file (if enabled).
3. On miss, execute query callback in `QueryMixin`.
4. On lower-layer hit, optionally backfill higher layers.
5. On query execution success, write-through to enabled cache layers.
6. Return value + metadata (`source`, `stale`, `latency`).

### 6.3 Write/Invalidate Flow (default)

- Successful query execution results write-through to configured cache layers.
- Repo lifecycle hooks trigger namespace or key invalidation.
- Layer failures are isolated (best effort) unless policy marks them strict.

## 7. API Contracts

### 7.1 Core Models

```dart
// StorageKey contract is shared:
// see shared_storage_serialization_foundation_spec.md
abstract class CacheKey<T> implements StorageKey {}

enum CacheSource { memory, file, query }

class CacheEntry<T> {
  const CacheEntry({
    required this.value,
    required this.createdAt,
    this.expiresAt,
    this.etag,
  });

  final T value;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? etag;

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

class CacheResult<T> {
  const CacheResult({
    required this.value,
    required this.source,
    required this.isStale,
  });

  final T value;
  final CacheSource source;
  final bool isStale;
}
```

### 7.2 Policy Model

```dart
class CachePolicy<Serialized extends Object> {
  const CachePolicy({
    this.useMemory = true,
    this.useFile = false,
    this.memoryTtl,
    this.fileTtl,
    this.allowStaleFileOnQueryError = true,
    this.writeThrough = true,
    this.backfillHigherLayers = true,
    this.cacheNullResults = true,
    this.strictLayerErrors = false,
    this.onSchemaMismatch,
  });

  final bool useMemory;
  final bool useFile;
  final Duration? memoryTtl;
  final Duration? fileTtl;
  final bool allowStaleFileOnQueryError;
  final bool writeThrough;
  final bool backfillHigherLayers;
  final bool cacheNullResults;
  final bool strictLayerErrors;
  final SchemaMismatchResolver<Serialized>? onSchemaMismatch;
}
```

### 7.3 Layer Contract

```dart
abstract class CacheLayerService extends Service {
  int get priority; // lower is earlier in read order

  Future<CacheEntry<T>?> read<T, Serialized extends Object>(
    CacheKey<T> key, {
    SerializationCodec<T, Serialized>? codec,
  });
  Future<void> write<T, Serialized extends Object>(
    CacheKey<T> key,
    CacheEntry<T> entry, {
    SerializationCodec<T, Serialized>? codec,
  });
  Future<void> invalidate<T>(CacheKey<T> key);
  Future<void> clearNamespace(String namespace);
}

abstract class MemoryCacheLayerService extends CacheLayerService {
  @override
  int get priority => 0;
}

abstract class FileCacheLayerService extends CacheLayerService {
  @override
  int get priority => 1;
}
```

### 7.4 Pipeline Contract

```dart
abstract class CachePipelineService extends Service {
  Future<CacheResult<T>?> get<T, Serialized extends Object>({
    required CacheKey<T> key,
    required CachePolicy<Serialized> policy,
    SerializationCodec<T, Serialized>? codec,
  });

  Future<void> put<T, Serialized extends Object>(
    CacheKey<T> key,
    T value, {
    required CachePolicy<Serialized> policy,
    SerializationCodec<T, Serialized>? codec,
  });

  Future<void> invalidate<T>(CacheKey<T> key);
  Future<void> clearNamespace(String namespace);
}
```

### 7.5 Shared Foundation Contracts

This spec imports shared contracts from:

- `spec/shared_storage_serialization_foundation_spec.md`

Imported contracts:

- `StorageKey`
- `SerializationCodec<Data, Serialized extends Object>`
- `SchemaMismatchResolver<Serialized>`
- `SchemaMismatchContext<Serialized>`
- `SchemaMismatchDecision<Serialized>`

This spec only defines query-cache-specific services/models on top of those base contracts.

## 8. Default Implementations

### 8.1 `MemoryCacheLayerService`

- abstract layer type for all L1 memory cache implementations
- default implementation wraps existing in-memory cache package
- no serialization required
- very short default TTL
- process-lifetime only

### 8.2 `FileCacheLayerService`

- abstract layer type for all L2 file/persistent cache implementations
- default implementation stores serialized entries by storage key
- handles TTL and expiration checks
- tolerates corrupted entries by evicting and treating as miss

### 8.3 `DefaultCachePipelineService`

Responsibilities:

1. Resolve typed layer dependencies (`MemoryCacheLayerService`, `FileCacheLayerService`) and apply policy.
2. Read in configured order.
3. Distinguish miss vs expired vs stale-allowed responses.
4. Backfill/writethrough based on policy.
5. Emit telemetry attributes for source/miss/fallback/error.

## 9. Integration with Existing Mixins and Repos

### 9.1 `QueryMixin` Evolution (non-breaking)

Current behavior is memory-only with local `MemoryCache` instance.

Proposed behavior:

1. If `CachePipelineService` is available in DI and feature enabled:
   - ask pipeline for cache value (`get`)
   - on miss, execute query callback locally
   - persist result through pipeline (`put`) based on policy
2. Else:
   - fallback to existing in-memory behavior (compat mode)

This preserves existing behavior for adopters who do nothing.

### 9.2 New query API surface (additive)

```dart
Future<QueryResult?> query<QueryResult, Serialized extends Object>(
  String name,
  FutureOr<QueryResult> Function(T data) query, {
  Object? cacheKey,
  CachePolicy<Serialized>? cachePolicy,
  SerializationCodec<QueryResult, Serialized>? codec,
  Duration? ttl, // backward-compatible shorthand
  ...
})
```

Compatibility rules:

- `ttl` maps into memory/file TTL when `cachePolicy` is not supplied.
- old callsites continue to compile and behave as before.

### 9.3 Repo-level defaults

Add optional getters in mixin/repo:

- `CachePolicy<Object> get defaultCachePolicy`
- `String get cacheNamespace`

These can be overridden per repo.

## 10. DI and Override Model

### 10.1 Root-level builder additions

In `RootModule` add builders similar to existing service builders:

- `cachePipelineServiceBuilder`
- `memoryCacheLayerServiceBuilder`
- `fileCacheLayerServiceBuilder`

Default behavior:

- register pipeline + default `MemoryCacheLayerService` implementation only
- file layer remains optional unless explicitly configured and enabled by policy
- root module chooses the concrete implementation class for each typed layer service

### 10.2 Module-level overrides

Modules can replace any cache service in `bindServices`.

Examples:

- encrypted file layer for sensitive modules
- custom namespace strategy per module
- shorter TTL for highly volatile features

### 10.3 Per-query overrides

Each query call can override policy/codec/key details without affecting global defaults.

## 11. Opt-In Strategy

Three independent opt-in switches:

1. **Global**: app enables pipeline services in root module.
2. **Repo**: repo chooses to use cache policy defaults / namespace.
3. **Query**: individual query provides `cacheKey` and optional policy.

If any level omits cache configuration, query works normally without cache.

## 12. Error and Fallback Semantics

1. Layer read failure:
   - default: log + continue to next layer
   - strict mode: throw immediately
2. Corrupted file entry:
   - evict key and treat as miss
3. Query execution failure after cache miss:
   - if stale file entry exists and policy allows, return stale
   - otherwise propagate error/null per query contract
4. Write-through failure:
   - default non-fatal; should not fail successful query result

## 13. Telemetry and Analytics

Per query span attributes (minimum):

- `cache.namespace`
- `cache.key_hash` (not raw key)
- `cache.hit` (`true`/`false`)
- `cache.source` (`memory`/`file`/`query`)
- `cache.stale` (`true`/`false`)
- `cache.layer_errors` (count)

Optional analytics event enrichment:

- cache source
- stale fallback occurrence

No PII should be logged in raw keys.

## 14. Concurrency, Consistency, and Invalidation

### 14.1 Request coalescing (recommended)

`QueryMixin` may deduplicate concurrent in-flight misses for the same key:

- first request executes query callback on cache miss
- followers await same future

This prevents thundering herd on misses.

### 14.2 Versioned keys

Keep a data/version component in key derivation where appropriate to prevent stale cross-version reads.

### 14.3 Invalidation hooks

Reuse existing repo lifecycle hooks:

- on data/update: invalidate key or namespace based on repo policy
- on loading/error: optional invalidation (compatible with current settings)
- on dispose: clear repo namespace

## 15. Security and Data Governance

1. File layer must support encryption hooks (or pluggable secure storage adapter).
2. Cache policy should allow disabling file cache for sensitive types.
3. Namespace design must avoid collisions across users/tenants.
4. Include schema fingerprint in key to prevent unsafe decode after model changes.
5. Support optional manual compatibility version when old snapshots are intentionally readable.

## 16. Performance Considerations

1. Memory layer should remain O(1) for common lookups.
2. File reads should be batched/async and avoid main-thread blocking.
3. Backfill writes should be async; avoid adding latency to cache hit path.
4. Large payloads may skip memory layer based on policy thresholds (future extension).

## 17. Implementation Plan

### Phase 0: Foundation (additive, no behavior changes)

1. Introduce cache contracts/models (`CacheKey`, `CachePolicy`, `CacheResult`, `SerializationCodec`).
2. Add `StorageKey` shared contract and update key models to implement it.
3. Add service interfaces for layers + pipeline.
4. Add exports without wiring defaults yet.

### Phase 1: Default pipeline with memory parity

1. Implement `MemoryCacheLayerService`.
2. Implement `DefaultCachePipelineService` with cache `get/put` semantics only.
3. Integrate source_gen-based `schemaId` generation for built-in codecs/key factories.
4. Keep `QueryMixin` fallback path unchanged.
5. Add test parity with current memory behavior.

### Phase 2: Persistent file layer

1. Implement `FileCacheLayerService` with codec support.
2. Add policy flags for file enablement/TTL/stale fallback.
3. Add corruption handling + stale read tests.

### Phase 3: DI wiring and override points

1. Add root builders and default registrations.
2. Document module/repo/query override patterns.
3. Add integration tests proving override precedence.

### Phase 4: Migration and cleanup

1. Document migration from direct `MemoryCache` usage to pipeline usage.
2. Optionally deprecate direct `QueryMixin.cache` field in later cycle.
3. Keep compatibility layer for at least one minor release.

## 18. Proposed File Layout

Shared foundation files are defined by:

- `spec/shared_storage_serialization_foundation_spec.md`

Add under `lib/src/domain/models/`:

- `cache_key.dart`
- `cache_policy.dart`
- `cache_result.dart`
- `cache_entry.dart`

Add under `lib/src/domain/services/`:

- `cache_pipeline_service.dart`
- `cache_layer_service.dart`
- `memory_cache_layer_service.dart`
- `file_cache_layer_service.dart`

Add under `lib/src/infra/services/`:

- `default_cache_pipeline_service.dart`
- `memory_cache_layer_service.dart`
- `file_cache_layer_service.dart`

Add under `lib/src/utils/` (optional):

- `cache_key_factory.dart`

Update exports:

- `lib/src/domain/models/models.dart`
- `lib/src/domain/services/services.dart`
- `lib/src/infra/services/services.dart`
- `lib/src/utils/utils.dart` (if codec/key helpers are placed there)

## 19. Test Plan

### 19.1 Unit tests: pipeline

1. memory hit returns cached value
2. memory miss + file hit backfills memory
3. full miss returns cache miss
4. stale file entry behavior is surfaced correctly for caller fallback decisions
5. strict mode propagates layer failure
6. read/put ordering and backfill behavior are deterministic

### 19.2 Unit tests: file layer

1. encode/decode roundtrip via codec
2. TTL expiration yields miss
3. corrupted payload is evicted and treated as miss
4. namespace clear removes only matching keys

### 19.3 Integration tests: query mixin

1. no pipeline registered => legacy memory behavior unchanged
2. pipeline registered => uses configured layers
3. per-query policy overrides repo defaults
4. lifecycle hook invalidation still functions
5. full miss executes query callback and writes-through
6. query execution failure returns stale file when enabled
7. concurrent same-key misses are deduplicated

### 19.4 Regression tests

Port existing query mixin cache tests and verify no behavior regressions under default setup.

## 20. Rollout and Migration Guidance

1. Ship contracts and default memory pipeline behind additive API.
2. Migrate internal `QueryMixin` internals first, keep external signature stable.
3. Introduce file layer as explicit opt-in (`useFile: true`).
4. Publish cookbook examples:
   - memory-only (default)
   - memory + file
   - memory + file + stale-on-query-failure fallback
5. Add deprecation notices only after adoption data confirms parity.

## 21. Open Questions

1. Should `SerializationCodec` live in `domain` or `utils` layer boundaries?
2. Should stale fallback be controlled globally, per-repo, or per-query by default?
3. Should cache namespace default include user/session identifier automatically?
4. Do we expose cache statistics API for observability dashboards in runtime?
5. For non-generated codecs, should `schemaId` be required explicitly or auto-derived from runtime type metadata?
