# Repo State Persistence and Bootstrap Sync Spec

Status: Implemented
Owner: grumpy runtime
Target: durable repo state hydration at startup + background synchronization with remote

## 1. Problem Statement

The current runtime supports in-memory repo state and query-level caching, but it does not define a first-class mechanism to:

- persist canonical repo state across app restarts
- hydrate repos from local state immediately at startup
- run deterministic follow-up sync with remote sources
- expose policy controls for staleness, fallback, and conflict handling

As a result, apps can experience cold-start loading screens and duplicated custom logic per repo for persistence and bootstrap sync.

## 2. Goals

1. Enable repo-level durable state persistence (file or equivalent local storage).
2. Hydrate repo state quickly on startup before remote sync completes.
3. Keep bootstrap sync behavior configurable and opt-in per repo.
4. Preserve existing `Repo<T>` semantics (`loading`, `data`, `error`) without breaking current APIs.
5. Support overridable infrastructure via DI and `RootModule` builders.
6. Keep clear separation from query-result cache pipeline responsibilities.

## 3. Non-Goals

1. Full offline-first bidirectional sync engine with server merge protocols.
2. Cross-repo transactional guarantees in v1.
3. Mandatory persistence for all repos.
4. Replacing domain repos with generic key/value stores.

## 4. Relationship to Query Cache Pipeline

This spec is complementary to `multi_layer_cache_pipeline_spec.md`.
It also depends on shared base contracts from
`spec/shared_storage_serialization_foundation_spec.md`.

Separation of concerns:

- Query Cache Pipeline:
  - caches derived query/read results
  - key-scoped and query-input-scoped
- Repo State Persistence:
  - stores canonical repo state snapshots
  - repo-scoped lifecycle (hydrate on init, persist on updates)

Rule:

- query cache must not be the source of truth for repo bootstrap
- repo snapshot is the source for startup hydration

## 5. Architectural Decision

Introduce a dedicated **Repo State Persistence Service** and **Repo Bootstrap Coordinator** contract:

- persistence service owns load/save/delete of serialized repo snapshots
- bootstrap coordinator defines hydration + sync sequence
- repos opt in via mixin/hooks and policy configuration

This keeps persistence/sync logic out of ad-hoc repo code and consistent with the runtime’s service-based architecture.

## 6. High-Level Model

Each participating repo has:

- snapshot key (namespace + repo type + schema fingerprint)
- snapshot payload (`T` data + metadata)
- persistence policy (TTL, save triggers, corruption behavior)
- bootstrap sync policy (when/how to sync remote after hydrate)

Startup behavior:

1. Repo initializes.
2. Attempt local snapshot load.
3. If valid snapshot exists, emit `data(snapshot)` immediately.
4. Trigger remote sync according to policy.
5. On sync success, emit updated `data` and persist new snapshot.
6. On sync failure, preserve hydrated data and expose staleness/sync error metadata.

## 7. API Contracts

### 7.1 Core Models

```dart
class RepoSnapshotKey implements StorageKey {
  const RepoSnapshotKey({
    required this.namespace,
    required this.repoType,
    required this.schemaId,
    this.compatVersion,
    this.userScope,
  });

  final String namespace;
  final String repoType;
  final String schemaId;    // source_gen fingerprint of serialized shape
  final int? compatVersion; // optional manual compatibility channel
  final String? userScope;

  @override
  String asStorageKey() {
    final userPart = userScope == null ? '' : '|u=$userScope';
    final compatPart = compatVersion == null ? '' : '|c=$compatVersion';
    return '$namespace|$repoType|$schemaId$compatPart$userPart';
  }
}

class RepoSnapshot<T> {
  const RepoSnapshot({
    required this.data,
    required this.savedAt,
    this.expiresAt,
    this.lastSyncAt,
    this.metadata = const {},
  });

  final T data;
  final DateTime savedAt;
  final DateTime? expiresAt;
  final DateTime? lastSyncAt;
  final Map<String, Object?> metadata;

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);
}
```

### 7.2 Policy Models

```dart
enum BootstrapHydrationMode {
  hydrateThenSync,
  syncThenHydrate,
  hydrateOnly,
  syncOnly,
}

enum SyncFailureBehavior {
  keepHydratedData,
  emitErrorState,
  silent,
}

class RepoPersistencePolicy<Serialized extends Object> {
  const RepoPersistencePolicy({
    this.enabled = false,
    this.snapshotTtl,
    this.persistOnData = true,
    this.persistDebounce = const Duration(milliseconds: 300),
    this.deleteOnCorruption = true,
    this.saveNullData = false,
    this.onSchemaMismatch,
  });

  final bool enabled;
  final Duration? snapshotTtl;
  final bool persistOnData;
  final Duration persistDebounce;
  final bool deleteOnCorruption;
  final bool saveNullData;
  final SchemaMismatchResolver<Serialized>? onSchemaMismatch;
}

class RepoBootstrapPolicy {
  const RepoBootstrapPolicy({
    this.mode = BootstrapHydrationMode.hydrateThenSync,
    this.syncAfterHydration = true,
    this.allowExpiredHydration = true,
    this.syncTimeout,
    this.failureBehavior = SyncFailureBehavior.keepHydratedData,
  });

  final BootstrapHydrationMode mode;
  final bool syncAfterHydration;
  final bool allowExpiredHydration;
  final Duration? syncTimeout;
  final SyncFailureBehavior failureBehavior;
}
```

### 7.3 Shared Foundation Contracts

This spec imports shared contracts from:

- `spec/shared_storage_serialization_foundation_spec.md`

Imported contracts:

- `StorageKey`
- `SerializationCodec<Data, Serialized extends Object>`
- `SchemaMismatchResolver<Serialized>`
- `SchemaMismatchContext<Serialized>`
- `SchemaMismatchDecision<Serialized>`

This spec only defines repo-persistence-specific services/models on top of those base contracts.

### 7.4 Persistence Service Contract

```dart
abstract class RepoStatePersistenceService extends Service {
  Future<RepoSnapshot<T>?> load<T, Serialized extends Object>(
    RepoSnapshotKey key, {
    required SerializationCodec<T, Serialized> codec,
  });

  Future<void> save<T, Serialized extends Object>(
    RepoSnapshotKey key,
    RepoSnapshot<T> snapshot, {
    required SerializationCodec<T, Serialized> codec,
  });

  Future<void> delete(RepoSnapshotKey key);
  Future<void> clearNamespace(String namespace);
}
```

### 7.5 Bootstrap Coordinator Contract

```dart
typedef RepoSyncLoader<T> = Future<T?> Function();

abstract class RepoBootstrapService extends Service {
  Future<void> bootstrap<T, Serialized extends Object>({
    required Repo<T> repo,
    required RepoSnapshotKey key,
    required SerializationCodec<T, Serialized> codec,
    required RepoPersistencePolicy<Serialized> persistencePolicy,
    required RepoBootstrapPolicy bootstrapPolicy,
    required RepoSyncLoader<T> sync,
    required FutureOr<void> Function(T value) emitData,
    required FutureOr<void> Function(Object error, StackTrace? st) emitError,
  });
}
```

## 8. Default Implementations

### 8.1 `FileRepoStatePersistenceService`

- default persistent implementation using file/local storage
- stores serialized snapshot envelope (payload + timestamps + metadata)
- detects corruption and optionally deletes invalid entries

### 8.2 `DefaultRepoBootstrapService`

Responsibilities:

1. Evaluate `RepoBootstrapPolicy` mode.
2. Perform hydration attempt (if enabled).
3. Perform sync attempt (if enabled).
4. Apply sync failure behavior deterministically.
5. Persist synchronized data according to persistence policy.
6. Emit telemetry attributes for hydrate hit/miss/expired/sync outcome.

## 9. Repo Integration Strategy

Use additive mixin-based integration to avoid breaking existing repos.

### 9.1 New mixin proposal

```dart
mixin PersistentRepoStateMixin<T, Serialized extends Object>
    on Repo<T>, RepoLifecycleHooksMixin<T>, TelemetryMixin {
  RepoPersistencePolicy<Serialized> get persistencePolicy =>
      const RepoPersistencePolicy();
  RepoBootstrapPolicy get bootstrapPolicy => const RepoBootstrapPolicy();

  RepoSnapshotKey get snapshotKey;
  SerializationCodec<T, Serialized> get snapshotCodec;

  /// Remote loader for initial sync.
  Future<T?> syncFromRemote();

  @mustCallInConstructor
  void installRepoStatePersistenceHooks();
}
```

### 9.2 Behavior

When installed:

1. on repo initialization/activation, invoke `RepoBootstrapService.bootstrap`.
2. on `data(...)`, persist debounced snapshot when enabled.
3. on dispose, flush pending save operations.

### 9.3 Backward compatibility

- repos not mixing in persistence behavior are unchanged
- existing query cache and mutation behavior remains unaffected

## 10. DI and Override Model

### 10.1 Root-level builder additions

In `RootModule` add:

- `repoStatePersistenceServiceBuilder`
- `repoBootstrapServiceBuilder`

Default behavior:

- register `DefaultRepoBootstrapService`
- persistence service can default to a no-op implementation unless configured

### 10.2 Module-level overrides

Modules may replace:

- storage backend (encrypted file persistence, SQLite-backed persistence)
- bootstrap strategy (aggressive sync vs conservative sync)

### 10.3 Repo-level overrides

Each repo defines:

- snapshot key strategy
- serialization codec
- persistence/bootstrap policy
- sync loader behavior

## 11. Detailed Bootstrap Modes

### 11.1 `hydrateThenSync` (default)

1. load snapshot
2. emit data if present (and allowed by expiration policy)
3. run remote sync
4. emit/persist synced data

Best UX for cold start speed.

### 11.2 `syncThenHydrate`

1. attempt remote sync first
2. on sync failure, fallback to snapshot hydration

Useful for domains requiring freshest possible state.

### 11.3 `hydrateOnly`

1. load snapshot
2. do not sync automatically

Useful for low-connectivity or explicitly manual sync flows.

### 11.4 `syncOnly`

1. skip snapshot hydration
2. always fetch remote

Useful when local persistence is disabled by policy/security.

## 12. Error and Fallback Semantics

1. Snapshot missing:
   - proceed with sync path based on mode
2. Snapshot expired:
   - hydrate only when `allowExpiredHydration` is true
3. Snapshot decode corruption:
   - optionally delete corrupted entry
   - continue as cache miss
4. Sync failure after hydration:
   - behavior controlled by `failureBehavior`
5. Persistence save failure:
   - non-fatal by default; telemetry + logs only

## 13. Telemetry and Analytics

Required telemetry attributes:

- `repo.bootstrap.mode`
- `repo.snapshot.hit`
- `repo.snapshot.expired`
- `repo.snapshot.corrupted`
- `repo.sync.started`
- `repo.sync.success`
- `repo.sync.duration_ms`

Optional analytics:

- startup hydration source
- stale-on-start indicator

## 14. Concurrency and Lifecycle

1. Bootstrap should be idempotent per activation cycle.
2. Parallel bootstrap calls for same repo instance must coalesce.
3. Disposal should cancel or ignore late bootstrap completions.
4. Debounced save queue should flush safely before repo free.

## 15. Security and Privacy

1. Support encrypted-at-rest storage adapters.
2. Namespace keys should include user/account scope when relevant.
3. Avoid logging raw snapshot payloads.
4. Provide per-repo opt-out for sensitive domains.
5. Prefer auto-generated schema fingerprints to avoid manual-version drift.

## 16. Performance Considerations

1. Hydration decode should avoid blocking UI-critical path.
2. Save operations should be debounced and async.
3. Snapshot size should be bounded (future optional max-bytes policy).
4. Large repos may require chunking or alternate store backends.

## 17. Implementation Plan

### Phase 0: Contracts and no-op defaults

1. Add snapshot models and policy models.
2. Add shared `StorageKey` contract and update snapshot key to implement it.
3. Add persistence/bootstrap service interfaces.
4. Add no-op persistence implementation.

### Phase 1: File-backed persistence

1. Implement `FileRepoStatePersistenceService`.
2. Integrate source_gen-based `schemaId` generation for built-in codecs/keys.
3. Implement codec and corruption handling tests.
4. Wire root builder defaults.

### Phase 2: Bootstrap orchestration

1. Implement `DefaultRepoBootstrapService`.
2. Add bootstrap mode coverage tests.
3. Add sync failure behavior tests.

### Phase 3: Repo mixin integration

1. Add `PersistentRepoStateMixin`.
2. Integrate lifecycle hooks.
3. Provide migration examples for existing repos.

### Phase 4: Hardening

1. Add coalescing/cancellation protections.
2. Add telemetry dashboards/counters.
3. Evaluate deprecating ad-hoc persistence patterns.

## 18. Proposed File Layout

Shared foundation files are defined by:

- `spec/shared_storage_serialization_foundation_spec.md`

Add under `lib/src/domain/models/`:

- `repo_snapshot_key.dart`
- `repo_snapshot.dart`
- `repo_persistence_policy.dart`
- `repo_bootstrap_policy.dart`

Add under `lib/src/domain/services/`:

- `repo_state_persistence_service.dart`
- `repo_bootstrap_service.dart`

Add under `lib/src/infra/services/`:

- `file_repo_state_persistence_service.dart`
- `default_repo_bootstrap_service.dart`
- `noop_repo_state_persistence_service.dart`

Add under `lib/src/utils/`:

- `persistent_repo_state_mixin.dart`

Update exports:

- `lib/src/domain/models/models.dart`
- `lib/src/domain/services/services.dart`
- `lib/src/infra/services/services.dart`
- `lib/src/utils/utils.dart`

## 19. Test Plan

### 19.1 Unit tests: persistence service

1. save/load roundtrip via serialization codec
2. TTL/expiration handling
3. corruption delete-on-read behavior
4. namespace clear behavior

### 19.2 Unit tests: bootstrap service

1. `hydrateThenSync` hydrates then syncs
2. `syncThenHydrate` fallback behavior
3. `hydrateOnly` skips sync
4. `syncOnly` ignores snapshot
5. failure behavior modes are respected

### 19.3 Integration tests: repo mixin

1. repo emits hydrated data at startup
2. sync updates hydrated data and persists snapshot
3. sync failure keeps hydrated data when configured
4. data updates are persisted with debounce
5. concurrent bootstraps are coalesced

### 19.4 Regression tests

1. repos without persistence mixin behave exactly as before
2. query cache pipeline remains unaffected

## 20. Rollout and Migration Guidance

1. Ship contracts and no-op defaults first.
2. Introduce file persistence and bootstrap service behind opt-in policy.
3. Migrate selected repos as pilot implementations.
4. Add cookbook docs:
   - startup hydration + sync
   - stale-data indicator handling
   - user-scoped snapshot keys
5. Expand adoption after telemetry confirms startup improvements.

## 21. Open Questions

1. Should bootstrap run on `initialize`, `activate`, or both by default?
2. Should snapshot metadata include sync etag/version fields in v1?
3. Do we need explicit observer API for "hydrated vs synced" UI states?
4. Should repo persistence share the same underlying store with query cache or remain isolated?
5. For repos without source_gen codecs, should `schemaId` be required manually or derived from codec type metadata?
