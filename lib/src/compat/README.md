# Compat

## What This Feature Owns

`compat` is a migration bridge for old import paths.

## Responsibilities

- Re-export symbols from new feature-based structure.
- Reduce breakage while downstream code migrates.

## Usage Policy

- New code should not import from `compat`.
- Existing imports should be migrated incrementally to owning feature folders.

## Retirement Strategy

1. Track remaining `compat` import usage.
2. Migrate call-sites feature by feature.
3. Remove unused compat re-exports.
4. Delete `compat` once external usage reaches zero.
  