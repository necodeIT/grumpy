# Module-Managed Injectable Lifecycle Spec

Status: Proposed
Owner: grumpy runtime
Target: first-class module lifecycle orchestration for lifecycle-capable Services and Datasources

## 1. Problem Statement

`Module` currently orchestrates lifecycle only for `Repo` instances.
`Service` and `Datasource` registrations are DI-only and are not lifecycle-managed by modules.

Consequences:

- lifecycle-capable service implementations can initialize themselves ad hoc (constructor-triggered `initialize()`), producing inconsistent behavior
- warm module reactivation semantics (`activate` / `deactivate`) are unavailable or fragmented for injectables
- dependency-change propagation (`dependenciesChanged`) is not consistently delivered to lifecycle-capable injectables
- module lifecycle guarantees are asymmetric across runtime building blocks

## 2. Goals

1. Make module lifecycle orchestration consistent across:
   - `Repo`
   - `Service` implementations that mix in `LifecycleMixin`
   - `Datasource` implementations that mix in `LifecycleMixin`
2. Keep API surface simple with no explicit opt-in flag on `Injectable`.
3. Preserve backward compatibility for non-lifecycle services/datasources.
4. Preserve warm lifecycle behavior:
   - initialize once per mounted singleton instance
   - activate/deactivate on module active-state transitions
5. Keep DI usage and module binding ergonomics unchanged for existing users.

## 3. Non-Goals

1. Lifecycle orchestration for factory-scoped lifecycle injectables.
2. Enforcing lifecycle support on all services/datasources.
3. Replacing module registry behavior or route-driven activation model.
4. Reworking `Repo` lifecycle design.

## 4. Decision Summary

Adopt **automatic lifecycle management by runtime type detection**:

- if a bound injectable instance `is LifecycleMixin`, module lifecycle manages it
- if not, it remains plain DI-only

No new explicit property like `managedByModuleLifecycle` is introduced.

Safety rule:

- lifecycle-capable injectables must be singleton-registered (`singelton == true`)
- attempting to bind a lifecycle-capable injectable as factory throws `StateError` during module initialization

Rationale:

- avoids API clutter and user error from manual flags
- aligns behavior with existing runtime capabilities already present in concrete services
- preserves simple default for non-lifecycle injectables

## 5. Scope of Change

Primary file:

- `lib/src/module.dart`

Secondary behavior/migration files:

- `lib/src/infra/services/routing_kit_routing_service.dart`
- `lib/src/infra/services/canonical_module_registry_service.dart`
- tests in `test/module_test.dart`
- docs in `README.md` (module lifecycle section)

No required changes to:

- `lib/src/domain/domain.dart` injectable contract

## 6. Lifecycle Model

### 6.1 Definitions

Lifecycle-capable injectable:

- any `Service` or `Datasource` instance that mixes in `LifecycleMixin`

Module-managed injectable:

- lifecycle-capable injectable bound as singleton and discovered by module binder

### 6.1.1 Readiness Invariant (Critical)

Factory-pattern DI access remains synchronous (`Service()` / `Datasource()` style),
but readiness is asynchronous and owned by module activation.

Invariant:

- concrete implementations that are lifecycle-managed must only be accessed
  after their owning module has completed `activate()`

Implications:

- routing/content paths must continue to await module activation before invoking
  code that may resolve lifecycle-managed injectables
- preview paths may run before activation only if they do not access
  lifecycle-managed injectables
- constructor-triggered `initialize()` is not an alternative readiness path

### 6.2 Lifecycle Phases

For each module-managed injectable instance:

1. `initialize()` is called exactly once (first module activation after creation)
2. `activate()` is called each time containing module activates
3. `deactivate()` is called each time containing module deactivates
4. `dependenciesChanged()` is called when containing module receives dependency-change signal
5. `free()` is invoked by DI scope disposal (existing behavior)

### 6.3 Ordering

Activation order inside module:

1. imported modules activate first (existing behavior)
2. module-managed injectables activate next
3. repos activate last (existing behavior remains)

Deactivation order inside module (reverse of acquisition semantics):

1. repos deactivate first
2. module-managed injectables deactivate next, in reverse activation order
3. imported modules deactivate last (existing behavior)

Dependencies changed order:

1. active module-managed injectables
2. active repos
3. imported modules may receive independently via their own invocations

## 7. Binding and Validation Rules

### 7.1 Detection Rule

During `bindServices` / `bindDatasources` registration path:

- create probe instance via builder (existing path already does this)
- if probe `is LifecycleMixin`, mark type as lifecycle-managed

### 7.2 Scope Rule

If probe is lifecycle-capable and `probe.singelton == false`:

- throw `StateError` with actionable message:
  - includes injectable runtime type
  - states lifecycle-capable injectables must be singleton
  - suggests setting `singelton => true` or removing `LifecycleMixin`

### 7.3 Registration Rule

Existing DI registration style remains:

- singleton injectables use `registerLazySingleton`
- factory injectables use `registerFactory`

Additional module bookkeeping is attached only for lifecycle-capable singleton injectables.

## 8. Module Runtime Bookkeeping

Module adds internal tracking, analogous to repo tracking:

- resolver list for lifecycle-managed injectables (service+datasource)
- active instance list
- active instance set for dedupe
- initialized instance set

Behavior:

- on first resolve of an instance, call `initialize()` once and record initialized
- when module activates, call `activate()` for each resolved managed instance
- when module deactivates, call `deactivate()` reverse order and clear active list/set
- initialized set remains so warm reactivation does not reinitialize

## 9. Migration Requirements for Existing Infra Services

### 9.1 Constructor-Driven Initialization

Lifecycle-capable services currently calling `initialize()` in constructor must stop doing so.

Affected examples:

- `lib/src/infra/services/routing_kit_routing_service.dart`
- `lib/src/infra/services/canonical_module_registry_service.dart`

Required change:

- remove constructor-time `initialize()` invocation
- rely on module lifecycle orchestration exclusively

Reason:

- avoids double initialization and ordering races once module begins lifecycle management

### 9.2 Singleton Confirmation

Lifecycle-capable services must remain singleton (`singelton => true`) either by default or explicit override.

## 10. Error Handling and Edge Cases

1. Duplicate resolution:
   - dedupe by object identity in active set
2. Async lifecycle failures:
   - activation/deactivation should fail fast and bubble errors to caller
3. Re-entrant activate/deactivate:
   - honor existing module `_isActive` guard behavior
4. Import interactions:
   - imported modules manage their own injectables independently
5. Disposal:
   - lifecycle-managed injectables still disposed by DI scope through existing disposable hooks

## 11. Testing Plan

### 11.1 New/Updated Unit Tests (`test/module_test.dart`)

1. lifecycle singleton service is initialized once and activated/deactivated per module cycle
2. lifecycle singleton datasource is initialized once and activated/deactivated per module cycle
3. lifecycle `dependenciesChanged` is propagated to active managed injectables
4. non-lifecycle service/datasource remain unaffected (no lifecycle calls)
5. lifecycle factory service binding throws `StateError`
6. lifecycle factory datasource binding throws `StateError`
7. managed injectables are deactivated before module free and disposed by scope teardown
8. warm reactivation does not call initialize twice
9. lifecycle-managed injectable resolved after `module.activate()` is ready
   (initialization+activation completed)
10. accessing lifecycle-managed injectable before activation fails with clear error
    (or test-only readiness guard assertion), preventing silent race conditions
11. routing integration: final content callback runs only after required modules
    are activated; service access from content path succeeds deterministically
12. routing integration: preview callback executes before activation and must not
    depend on lifecycle-managed injectables

### 11.2 Regression Coverage

Ensure existing tests still pass for:

- repo activation/deactivation warm behavior
- import module mount/dispose behavior
- singleton/factory identity behavior for non-lifecycle injectables
- module registry serialized activation (`sync`) remains the single readiness gate

## 12. Documentation Updates

Update `README.md`:

- clarify that services/datasources may mix in `LifecycleMixin`
- specify automatic module management rule (`is LifecycleMixin`)
- specify singleton requirement for lifecycle-capable injectables
- note that constructor-triggered `initialize()` should not be used for module-managed injectables

## 13. Rollout Plan

1. Implement module lifecycle bookkeeping and validation.
2. Remove constructor-time `initialize()` from lifecycle-capable infra services.
3. Add/adjust tests.
4. Update README and changelog.
5. Run full test suite.

## 14. Compatibility and Risk Assessment

Compatibility:

- non-lifecycle injectables: fully backward compatible
- lifecycle singleton injectables: behavior becomes deterministic and module-driven
- lifecycle factory injectables: now hard-fail at bind time (intentional safety break)

Primary risks:

1. Existing projects with lifecycle factory injectables will fail at initialization.
2. Implementations relying on constructor-side initialize side effects may observe ordering changes.

Mitigations:

- explicit error messages with migration guidance
- release note callout and examples

## 15. Open Questions

1. Should `dependenciesChanged()` be invoked only when module is active, or always?
   - Proposed: active only (consistent with active runtime graph)
2. Should managed injectable activation occur before or after repos?
   - Proposed: before repos, so repos can rely on active service dependencies
3. Should lifecycle-managed injectable sets be exposed for diagnostics?
   - Proposed: no public API in v1; keep internal until observability need is demonstrated

## 16. Acceptance Criteria

1. Module lifecycle automatically manages lifecycle-capable singleton services/datasources.
2. No explicit `Injectable` flag is required for lifecycle management.
3. Lifecycle-capable factory bindings fail fast with clear errors.
4. Infra lifecycle services do not self-initialize in constructors.
5. All lifecycle/module tests pass with new coverage.
6. README reflects finalized behavior.
7. The readiness invariant is enforced: lifecycle-managed concrete implementations
   are not considered safe for access before owning module activation completes.
