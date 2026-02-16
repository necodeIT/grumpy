# Repo

## What This Feature Owns

`repo` defines repository state semantics and repo-to-repo composition primitives.

## Responsibilities

- Define `Repo<T>` as the core reactive data boundary.
- Define `RepoState` model family (`loading`, `data`, `error`).
- Provide dependency composition helpers (`UseRepoMixin`).

## Key Concepts

- `Repo<T>`: lifecycle-managed, stream-backed state holder used by higher layers.
- `RepoState<T>`: explicit state machine to avoid nullable/implicit state.
- `UseRepoMixin`: watch dependent repos and rebuild derived state when upstream changes.

## What Does NOT Belong Here

- Query cache policies: see `cache`.
- Mutation conflict/retry policy: see `transactions`.
- Snapshot persistence/bootstrap strategy: see `persistence`.

## Practical Rule

Keep `repo` as the source of state shape and dependency composition; keep behavior policies in dedicated feature folders.
