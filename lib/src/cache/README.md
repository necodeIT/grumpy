# Cache

## What This Feature Owns

`cache` defines read-path caching contracts, policies, and multi-layer pipeline behavior.

## Responsibilities

- Define cache domain contracts (`CacheLayerService`, `CachePipelineService`).
- Define cache data model (`CacheKey`, `CacheEntry`, `CachePolicy`, `CacheResult`).
- Provide default memory/file implementations behind domain contracts.
- Provide query mixins for cache-aware repo reads.

## Key Concepts

- Multi-layer lookup: memory-first, then optional file layer.
- Write-through/backfill strategy to keep hot memory cache current.
- Explicit policy controls (TTL, stale handling, invalidation behavior).
- In-flight deduplication to avoid duplicate concurrent reads.

## Query Flow (Typical)

1. Validate repo/query setup.
2. Compute cache key + policy.
3. Check in-flight map for dedupe.
4. Read via cache pipeline.
5. On miss, execute query callback.
6. Write result according to policy.

## Guardrails

- Keep cache mechanics in this feature, not inside repo core.
- Infra implementations remain internal; public code targets domain interfaces.
