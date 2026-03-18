import 'dart:async';

import 'package:grumpy/grumpy.dart';

/// A no-operation implementation of [TelemetryService].
///
/// {@category telemetry}

class NoopTelemetryService extends TelemetryService {
  /// A no-operation implementation of [TelemetryService].
  NoopTelemetryService() : super.internal();

  @override
  Future<T> runSpan<T>(
    String name,
    FutureOr<T> Function() callback, {
    Map<String, dynamic>? attributes,
  }) async {
    log('runSpan $name called with attributes: $attributes');

    return callback();
  }

  @override
  String get logTag => 'NoopTelemetryService';

  @override
  void addSpanAttribute(String key, String value) {
    log('addSpanAttribute called with key: $key, value: $value');
  }

  @override
  FutureOr<void> destroy() {}

  @override
  Future<void> recordEvent(
    String name, {
    Map<String, dynamic>? attributes,
  }) async {
    log('recordEvent called with name: $name, attributes: $attributes');
  }

  @override
  Future<void> recordException(
    Object error, [
    StackTrace? stackTrace,
    Map<String, dynamic>? attributes,
  ]) async {
    log(
      'recordException called with error: $error, stackTrace: $stackTrace, attributes: $attributes',
    );
  }
}
