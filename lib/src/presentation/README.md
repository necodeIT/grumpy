# Presentation

## What This Feature Owns

`presentation` contains UI-facing composition primitives and adapters used by consuming apps.

## Responsibilities

- Expose view-facing constructs (`Leaf`, route-linked view semantics).
- Expose middleware abstractions for request/navigation interception at presentation boundary.
- Provide consumer-friendly presentation barrels.

## Key Concepts

- Presentation layer coordinates feature state and routing outcomes.
- Middleware at this layer should remain orchestration-focused, not domain-heavy.
- Repositories are consumed as read/write facades; business policy remains in domain features.

## Practical Guidance

- Keep UI composition and glue code here.
- Push domain rules into `repo`, `transactions`, `cache`, `persistence`, etc.
- Treat this layer as boundary adaptation, not core business logic.
