import 'dart:async';

import 'package:grumpy/grumpy.dart';

/// A no-operation implementation of [TelemetryService].
class NoopTelemetryService extends TelemetryService {
  @override
  noSuchMethod(Invocation invocation) {
    log('NoopTelemetryService: ${invocation.memberName} called.');
  }

  @override
  Future<T> runSpan<T>(
    String name,
    FutureOr<T> Function() callback, {
    Map<String, dynamic>? attributes,
  }) async {
    log(
      'NoopTelemetryService: runSpan $name called with attributes: $attributes',
    );

    return callback();
  }
}
