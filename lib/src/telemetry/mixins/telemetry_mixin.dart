import 'dart:async';

import 'package:grumpy/grumpy.dart';

/// A mixin that provides telemetry tracing capabilities.
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
