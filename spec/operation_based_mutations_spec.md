# Operation-Based Mutations Transaction Model Spec

Status: Proposed
Owner: grumpy runtime
Target: `MutationMixins` redesign for optimistic + concurrent writes

## 1. Problem Statement

Current `MutationMixins` behavior captures a single snapshot (`state`) at mutation start and writes completion results directly. With concurrent mutations this creates stale-write hazards:

- two mutations may both compute from older snapshots
- completion order determines final state, not user intent order
- optimistic updates can be overwritten by older in-flight completions

The system needs:

- optimistic UI updates with immediate feedback
- safe concurrency (multiple user actions in parallel)
- deterministic conflict handling
- compatibility with existing telemetry/analytics patterns

## 2. Goals

1. Preserve optimistic UX: local state updates immediately on user action.
2. Support concurrent in-flight mutations without stale final state corruption.
3. Encode conflict semantics explicitly (newer-wins when required).
4. Keep migration cost low for existing repos using `MutationMixins`.
5. Keep implementation modular and testable (avoid one giant mixin file).

## 3. Non-Goals

1. Global cross-repo transactions.
2. Full CRDT implementation.
3. Mandatory generic object diff/patch for all domain models in v1.
4. Breaking `RepoState` semantics (`loading/data/error`) in this phase.

## 4. Architectural Decision

Use a **hybrid approach**:

- thin mixin API on `Repo<T>` (ergonomic, consistent with current style)
- internal transaction engine class (`TxEngine<T>`) owning state and reconciliation
- domain operation contract (`TxOperation<T, TResult>`) representing user intent

Do **not** implement as a singleton/global service because pending transaction queues are per-repo instance and lifecycle-scoped.

## 5. High-Level Model

Each repo with transaction support maintains:

- `confirmedState`: server-acknowledged / durable local state
- `pendingOps`: ordered list of optimistic operations not fully settled
- `visibleState`: `pendingOps.fold(confirmedState, op.optimisticApply)`
- `version`: monotonically increasing confirmed version

Core rule:

- UI always renders `visibleState`
- on any op settle (success/failure), recompute `visibleState` from scratch
- never directly commit in-flight op output over current `visibleState`

## 6. API Contracts

### 6.1 TxOperation Contract

```dart
abstract interface class TxOperation<TState, TResult> {
  String get name;                  // telemetry span + analytics default
  String get id;                    // unique per enqueue
  int get baseVersion;              // version visible at enqueue time

  /// Deterministic optimistic transform. Must be pure.
  TState optimisticApply(TState current);

  /// Remote side effect / write request.
  Future<TResult> commit();

  /// Optional confirmation mapping.
  /// Return null to mean "confirmed state unchanged by response payload."
  TState? applyConfirmed(TState confirmed, TResult result);

  /// Failure policy for this op.
  bool shouldRollback(Object error, StackTrace? stackTrace);

  /// Conflict fields touched by this operation.
  /// Can be coarse-grained keys (e.g. "profile.name", "cart.items").
  Set<String> get touchedKeys;
}
```

Notes:

- `optimisticApply` must be pure and deterministic for replay/rebase safety.
- `touchedKeys` enables conflict policy without forcing object diffing.
- `applyConfirmed` lets server-returned canonical data adjust confirmed state.

### 6.2 Engine Surface

```dart
abstract interface class TxEngine<TState> {
  int get confirmedVersion;
  TState get confirmed;
  List<TxPending<TState>> get pending;

  TState computeVisible();

  Future<TxOutcome<TState>> enqueue<TResult>(TxOperation<TState, TResult> op);
}
```

### 6.3 Mixin Surface (Repo-facing)

```dart
mixin TransactionalMutationMixin<T>
    on Repo<T>, RepoLifecycleHooksMixin<T>, TelemetryMixin {
  @mustCallInConstructor
  void installTransactionHooks();

  Future<TxResult<T>> transact<TResult>(
    TxOperation<T, TResult> operation, {
    String? analyticsEvent,
    Map<String, String>? analyticsAttributes,
    RetryPolicy retryPolicy = RetryPolicy.noRetry,
  });
}
```

Compatibility helpers can keep legacy style:

```dart
Future<T?> mutate(
  String name,
  FutureOr<T> Function(T currentData) mutation, {
  ...
});
```

implemented internally as a simple `TxOperation`.

## 7. Conflict Resolution Model

Default v1 policy:

1. If `touchedKeys` are disjoint, both operations apply.
2. If overlapping keys exist, **newer enqueue order wins** for optimistic projection.
3. On settle, replay remaining pending ops in enqueue order over updated confirmed.

This delivers user-expected behavior:

- rapid edits on same field keep the latest local intent
- edits on different fields merge naturally

Extensibility:

- allow per-op custom conflict mode later (`newerWins`, `reject`, `merge`).

## 8. Execution Algorithm

### 8.1 Enqueue

1. Ensure repo has data (`RepoState.data`) or fail fast.
2. Build op with `baseVersion = confirmedVersion`.
3. Append op to `pendingOps`.
4. Recompute visible and emit `data(visible)`.
5. Start async commit pipeline (concurrent execution allowed).

### 8.2 Commit Success

1. Remove op from pending.
2. Update `confirmed`:
   - if `applyConfirmed` returns value, use it
   - else keep existing confirmed (for write-only endpoints)
3. Increment `confirmedVersion`.
4. Recompute visible from `confirmed + remaining pending`.
5. Emit `data(visible)`.

### 8.3 Commit Failure

1. Remove op from pending.
2. If `shouldRollback` is false:
   - keep `confirmed` unchanged
   - recompute visible from remaining pending
3. If `shouldRollback` is true:
   - same as above (rollback is implicit by removing failed op and replaying)
4. Emit error telemetry/logging without forcing `RepoState.error` by default.

### 8.4 Retry

- retain existing `RetryPolicy`
- retries apply only to `commit()`
- optimistic projection remains active while retrying

## 9. Why This Over Global Diff/Patch

Operation-based transactions:

- preserve domain intent (semantic operations)
- simplify deterministic replay
- localize conflict policy
- avoid fragile generic diff merge semantics for lists/maps/order changes

Typed diff/patch may still be added selectively where server contracts require it.
It should be optional and operation-specific, not mandatory for every model in v1.

## 10. File/Module Layout Proposal

Add focused files under `lib/src/utils/transactions/`:

- `tx_operation.dart` (interfaces + base classes)
- `tx_engine.dart` (core state machine/replay)
- `tx_models.dart` (`TxOutcome`, `TxResult`, pending metadata)
- `tx_conflict_policy.dart` (default key-overlap resolver)
- `tx_retry.dart` (retry wrapper, can reuse existing helper)
- `transactional_mutation_mixin.dart` (thin repo adapter)
- `legacy_mutation_adapter.dart` (optional bridge for existing `mutate`)

Update exports:

- `lib/src/utils/utils.dart`

Keep existing `mutation_mixins.dart` as compatibility wrapper during migration.

## 11. Telemetry and Analytics

Per operation:

- parent span: operation name
- child spans: retry attempts (`try_0`, `try_1`, ...)
- attributes:
  - `tx.id`
  - `tx.base_version`
  - `tx.pending_count_at_enqueue`
  - `tx.outcome` (`success`/`failure`)
  - `tx.retried` (`true`/`false`)

Analytics:

- default event: `mutation_<name>`
- include optional user attributes + system transaction metadata

## 12. Error Semantics

Default behavior:

- failed commit returns failure outcome to caller
- repo remains in `data` state when recoverable
- avoid flipping to global `RepoState.error` for isolated mutation failures

Optional future mode:

- configurable `emitRepoErrorOnMutationFailure`.

## 13. Migration Plan

### Phase 0: Introduce Engine (No API Break)

1. Add transaction engine and operation contracts.
2. Keep existing `MutationMixins` public API unchanged.
3. Internally route `mutate` and `action` through engine adapters.

### Phase 1: New Explicit API

1. Add `transact()` and operation primitives.
2. Document preferred migration path for advanced repos.

### Phase 2: Deprecation (Optional)

1. Soft-deprecate legacy mutation signatures when adoption is stable.
2. Keep adapter for at least one minor cycle.

## 14. Test Plan

### 14.1 Engine Unit Tests

1. enqueue emits optimistic state immediately
2. disjoint key operations merge
3. overlapping key operations follow newer-wins
4. out-of-order completion preserves replay-correct final state
5. failure removes operation and replays remaining pending
6. retry keeps optimistic projection active
7. `applyConfirmed` modifies confirmed and replays pending correctly

### 14.2 Mixin Integration Tests

1. telemetry spans and retry spans emitted correctly
2. analytics event naming + attributes preserved
3. legacy `mutate` parity with prior behavior for single in-flight mutation
4. concurrent mutation scenario no longer suffers stale overwrite

### 14.3 Regression Cases (from current tests)

Port and update:

- optimistic immediate visibility
- failure rollback behavior
- “concurrent mutations settle in completion order” must be replaced with
  deterministic transaction expectation (not last-completing-wins)

## 15. Performance Considerations

Replay cost is `O(p)` where `p = pendingOps.length`.

Mitigations:

- pending lists are usually small in UI flows
- keep `optimisticApply` pure and lightweight
- optional future optimization: incremental projection cache + invalidation

## 16. Invariants

1. `visible == replay(confirmed, pendingOps)` always.
2. pending op IDs are unique.
3. settle path (success/failure) always removes op exactly once.
4. no direct write from stale op result into `visible` without replay.

## 17. Open Questions

1. Should failed commits optionally emit `RepoState.error` behind config?
2. Should conflict keys be static strings or strongly typed key objects?
3. Do we need cancellation tokens for pending commits on repo disposal?
4. Should engine support max pending queue length backpressure?

## 18. Acceptance Criteria

Implementation is complete when:

1. existing public mutation APIs continue to work
2. concurrent stale overwrite bug class is eliminated
3. optimistic UX remains immediate
4. updated tests validate deterministic replay semantics
5. architecture remains split into focused files (no giant mixin)

