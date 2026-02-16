# Telemetry

## What This Feature Owns

`telemetry` provides observability abstractions (tracing + analytics) with safe defaults.

## Responsibilities

- Define tracing contract (`TelemetryService`).
- Define analytics contract (`AnalyticsService`).
- Provide context propagation primitives (`TelemetryContext`, zone mixin).
- Provide mixins for ergonomics in repos/services.

## Key Concepts

- Span lifecycle: start -> add attributes -> end (success/error).
- `TelemetryZoneMixin`: context propagation through async boundaries.
- `TelemetryMixin.trace(...)`: simple instrumentation wrapper around operations.
- No-op defaults: production-safe when no backend is configured.

## Extension Strategy

- Implement custom telemetry/analytics infra services.
- Bind them through `RootModule` builders.
- Keep call-sites backend-agnostic by using domain contracts and mixins.

## Guardrails

- Do not couple feature logic to specific vendors.
- Keep telemetry attributes stable and low-cardinality where possible.
