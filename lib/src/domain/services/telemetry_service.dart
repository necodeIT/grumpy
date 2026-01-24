import 'dart:async';

import 'package:grumpy/grumpy.dart';

/// A service interface for recording system-level telemetry, traces, and exceptions.
///
/// The [TelemetryService] defines a unified abstraction for **observability**
/// within an application — describing *what the system is doing*, not *what the
/// user is doing*. It is conceptually based on
/// [OpenTelemetry](https://opentelemetry.io/docs/concepts/) but is kept
/// lightweight, implementation-agnostic, and fully compatible with Dart’s
/// asynchronous model.
///
///
/// ## Overview
///
/// A [TelemetryService] is responsible for:
/// - Recording low-level **events** (e.g. `"api_request_started"`)
/// - Recording **exceptions** and stack traces
/// - Creating and managing **spans** that represent timed operations
/// - Propagating tracing context automatically across async boundaries
///
/// It provides the high-level interface only; concrete backends (such as
/// `SentryTelemetryService`, `OpenTelemetryService`, etc.) should implement the
/// actual recording logic.
///
///
/// ## Zone-based context propagation
///
/// Implementations should use [Zone]s to track the *current active span*.
/// This allows nested operations to automatically attach to the correct trace
/// without needing to pass span objects down the call stack.
///
/// The preferred way to manage this logic is through the
/// [`TelemetryZoneMixin`], which provides reusable helpers such as:
/// - `createContext()` — create a new span context
/// - `getContext()` — safely access the current context for the same service type
/// - `runSpan()` — execute a function in a new zone-scoped span
///
/// Example (conceptual):
///
/// ```dart
/// class SentryTelemetryService extends Service
///     with TelemetryZoneMixin<ISpan>
///     implements TelemetryService {
///
///   @override
///   Future<void> recordEvent(String name, {Map<String, String>? attributes}) {
///     Sentry.captureMessage(name);
///     return Future.value();
///   }
///
///   @override
///   Future<void> recordException(Object error, [StackTrace? stackTrace]) async {
///     await Sentry.captureException(error, stackTrace: stackTrace);
///   }
///
///   @override
///   Future<T> runSpan<T>(
///     String name,
///     FutureOr<T> Function() callback, {
///     Map<String, String>? attributes,
///   }) => runSpanWithZone(name, callback);
/// }
/// ```
///
///
/// ## When to use
/// Use [TelemetryService] for:
/// - Recording exceptions, performance timings, backend call durations, etc.
/// - Building traces across your application layers
/// - Reporting errors or warnings in a structured way
///
/// ## Releated
/// - [TelemetryZoneMixin] — for zone-based span management
/// - [TelemetryContext] — for the span execution context model
///
/// Do **not** use it for business or user analytics — for that, see
/// [AnalyticsService].
abstract class TelemetryService extends Service {
  /// Records a low-level telemetry event such as `"api_request_started"`.
  ///
  /// These events provide operational visibility into system behavior.
  /// They are not intended for product analytics.
  Future<void> recordEvent(String name, {Map<String, dynamic>? attributes});

  /// Records an exception or error with optional [stackTrace] and additional [attributes].
  ///
  /// Implementations should capture these to the telemetry backend
  /// (e.g., Sentry, OpenTelemetry, Datadog).
  Future<void> recordException(
    Object error, [
    StackTrace? stackTrace,
    Map<String, dynamic>? attributes,
  ]);

  /// Executes the provided [callback] within a new tracing span named [name].
  ///
  /// This should create a new [Zone] that inherits from the current span
  /// (if any), enabling nested traces to be automatically linked.
  ///
  /// Implementations are expected to:
  /// - Start a new span
  /// - Run the callback inside a zone carrying that span context
  /// - Finish the span when the callback completes (even if it throws)
  ///
  /// Example:
  /// ```dart
  /// await telemetry.runSpan('fetchUser', () async {
  ///   await api.getUser();
  /// });
  /// ```
  Future<T> runSpan<T>(
    String name,
    FutureOr<T> Function() callback, {
    Map<String, dynamic>? attributes,
  });

  /// Adds a key/value attribute to the currently active span, if any.
  ///
  /// Has no effect if called outside of an active telemetry context.
  void addSpanAttribute(String key, String value);
  @override
  String get group => '${super.group}.TelemetryService';
}
