# Persistence

## What This Feature Owns

`persistence` handles snapshot durability and bootstrap-time hydration/synchronization.

## Responsibilities

- Define snapshot models and persistence policies.
- Define persistence/bootstrap domain services.
- Provide default infra services for file-backed and noop behavior.
- Provide repo mixin for activation-time bootstrap + data-time persistence.

## Key Concepts

- Snapshot model: typed payload + timestamps + optional expiration.
- Bootstrap policy: hydrate-only, sync-only, hydrate-then-sync behaviors.
- Failure strategy: emit error state vs continue with existing state.
- Debounced persistence to avoid write amplification.

## Bootstrap Flow (Typical)

1. On repo activation, bootstrap starts once per activation cycle.
2. Optional hydrate from snapshot based on policy.
3. Optional remote sync.
4. Persist post-sync snapshot if enabled.

## Guardrails

- Persistence format changes should be version-aware and migration-safe.
- Keep storage-specific details in `infra/` implementations only.
