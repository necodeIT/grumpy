# Transactions

## What This Feature Owns

`transactions` provides mutation orchestration primitives: retries, optimistic projection, settlement, and conflict handling.

## Responsibilities

- Define retry/optimistic policy models.
- Define transaction operation and pending/result models.
- Define conflict resolution utilities (`newer-wins` by touched keys).
- Define `TxEngine` as the transaction service object.
- Provide repo mixins for action/mutation/transaction workflows.

## Key Concepts

- `TxOperation`: user intent contract (optimistic apply, commit, confirmed apply).
- `TxEngine`: confirmed state + pending queue -> computed visible state.
- Conflict policy: overlapping keys resolve deterministically.
- Settlement: success applies confirmed state; failure removes/rolls back pending op.

## Transaction Flow (Typical)

1. Enqueue operation with touched keys.
2. Emit optimistic visible state.
3. Commit with retry policy.
4. Settle success/failure.
5. Recompute visible state.

## Guardrails

- Keep optimistic transforms deterministic and side-effect free.
- Keep transaction internals here; do not leak infra-specific behavior into repos.
