# Module

## What This Feature Owns

`module` is the runtime composition layer. It defines how features are wired, scoped in DI, and activated/deactivated as a unit.

## Responsibilities

- Define module contracts (`Module`, `RootModule`).
- Bind services/datasources/repos into scoped DI containers.
- Orchestrate imported module mount/activation order.
- Provide canonical module graph management via `ModuleRegistryService`.

## Key Concepts

- `Module<RouteType, Config>`: feature unit with bindings and routes.
- `RootModule<RouteType, Config>`: app root with core default builders (routing, telemetry, cache, persistence, tx engine).
- `ModuleRegistryService`: canonicalizes module instances and synchronizes activation state.
- Scope discipline: each module gets an isolated DI scope; disposal pops back to import boundary.

## Lifecycle Model

1. `initialize`: register dependencies and imported modules.
2. `activate`: activate lifecycle-managed injectables, then repos.
3. `deactivate`: reverse order shutdown for warm stop.
4. `free`: hard teardown and scope cleanup.

## Extension Points

- Override `bindExternalDeps`, `bindServices`, `bindDatasources`, `bindRepos`.
- In `RootModule`, override service builders to swap default infra implementations.

## Guardrails

- Keep infra implementations internal to feature `infra/` folders.
- Avoid feature logic in modules; modules orchestrate wiring only.
