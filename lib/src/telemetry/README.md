# Telemetry

`telemetry` provides observability abstractions for tracing and analytics, with no-op defaults when no backend is configured. It exists so instrumentation calls stay backend-agnostic and feature code does not take a direct dependency on a vendor SDK.

The feature splits system observability from product analytics on purpose. `TelemetryService` handles spans, events, and exceptions, `AnalyticsService` handles user and product events, `TelemetryZoneMixin` propagates active span context through async work, and `TelemetryMixin` gives repos and services a short `trace(...)` helper instead of forcing them to resolve telemetry manually.

The names, attributes, and properties you pass into these APIs become backend-facing metadata, and `T` on `TelemetryContext<T>` is the backend-native span type used internally by a concrete implementation. Keep in mind that telemetry and analytics are separate concerns, no-op defaults mean instrumentation is safe before a real backend is wired, and telemetry attributes should stay stable and low-cardinality when possible.

For example:

```dart
await trace('load_settings', () async {
  return await datasource.fetchSettings();
});
```
