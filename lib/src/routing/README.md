# Routing

## What This Feature Owns

`routing` models routes and navigation behavior, including middleware-driven interception.

## Responsibilities

- Define route model types (`Route`, `LeafRoute`, `ModuleRoute`, `RouteContext`).
- Define the `RoutingService` contract.
- Coordinate route activation with module lifecycle.
- Support middleware-based navigation decisions and rewrites.

## Key Concepts

- `RouteContext`: immutable navigation input (path/query/fragment/params).
- Route tree: module routes for composition + leaf routes for concrete views.
- Middleware pipeline: sequential async interception before final route activation.
- Preview vs finalized navigation: enables pre-build and guarded transitions.

## Flow (High-Level)

1. Receive navigation request.
2. Build `RouteContext`.
3. Run middleware chain.
4. Resolve route + ensure required modules active.
5. Emit final view/content callback.

## Guardrails

- Route models should stay declarative.
- Runtime routing engine details belong in `infra/` only.
