# Shared

## What This Feature Owns

`shared` contains cross-cutting primitives that every other feature depends on. This folder should stay small and stable.

## Responsibilities

- Define base DI/lifecycle contracts used by services, datasources, repos, and modules.
- Provide common lifecycle and logging mixins.
- Provide serialization primitives shared by cache and persistence.
- Provide shared error and base model contracts.

## Key Concepts

- `Injectable`: the DI registration contract (`singelton` policy + lifecycle eligibility).
- `LifecycleMixin` and `LifecycleHooksMixin`: normalized object lifecycle (`initialize`, `activate`, `deactivate`, `dependenciesChanged`, `free`).
- `LogMixin`: consistent structured logger naming (`group` + `logTag`).
- `SerializationCodec<Data, Serialized>`: typed conversion boundary for storage/network surfaces.

## Design Rules

- Put code here only if at least two features need it.
- Do not put domain behavior here (cache logic, routing rules, transaction policy, etc).
- Keep abstractions framework-neutral and feature-neutral.

## Typical Dependency Direction

Feature code -> `shared` contracts/mixins -> concrete feature implementations.
