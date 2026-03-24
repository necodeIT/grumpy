import 'dart:async';

import 'package:grumpy/grumpy.dart';

/// Small convenience mixin for telemetry tracing.
///
/// Exposes a `trace(...)` helper that delegates to the configured
/// [TelemetryService].
///
/// Repos and services often want short instrumentation calls without resolving
/// telemetry manually every time.
///
/// [trace] resolves [TelemetryService] from DI and calls [TelemetryService.runSpan].
///
/// This mixin does not store any state; it is only a convenience wrapper.
///
/// - [name]: the span name.
/// - [function]: the work to execute inside the span.
/// - [attributes]: optional telemetry metadata.
///
/// For example:
/// ```dart
/// await trace('load_user', () async => datasource.fetchUser());
/// ```
///
/// {@category telemetry}

mixin TelemetryMixin {
  /// Wraps the given [function] in a Telemetry Span.
  ///
  /// Shorthand for obtaining the [TelemetryService] and calling [TelemetryService.runSpan].
  Future<T> trace<T>(
    String name,
    FutureOr<T> Function() function, {
    Map<String, dynamic>? attributes,
  }) async {
    final telemetry = TelemetryService();

    return telemetry.runSpan(name, function, attributes: attributes);
  }
}
