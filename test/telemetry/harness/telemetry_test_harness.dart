import 'dart:async';
import 'package:grumpy/grumpy.dart';

class TestTelemetryService extends TelemetryService
    with TelemetryZoneMixin<String> {
  TestTelemetryService() : super.internal();

  final startedSpans = <String>[];
  final parentSpans = <String?>[];
  final endedSpans = <(String, Object?)>[];
  final recordedExceptions = <Object>[];
  final attributes = <String, String>{};

  @override
  Future<void> recordEvent(
    String name, {
    Map<String, dynamic>? attributes,
  }) async {}

  @override
  Future<void> recordException(
    Object error, [
    StackTrace? stackTrace,
    Map<String, dynamic>? attributes,
  ]) async {
    recordedExceptions.add(error);
  }

  @override
  Future<T> runSpan<T>(
    String name,
    FutureOr<T> Function() callback, {
    Map<String, dynamic>? attributes,
  }) {
    return runSpanWithZone(name, callback, attributes: attributes);
  }

  @override
  FutureOr<String> onStartSpan(
    String name, {
    Map<String, dynamic>? attributes,
    TelemetryContext<String>? parent,
  }) {
    final span = 'span-$name';
    startedSpans.add(span);
    parentSpans.add(parent?.span);
    return span;
  }

  @override
  FutureOr<void> onEndSpan(String span, [Object? error]) {
    endedSpans.add((span, error));
  }

  @override
  void onAddAttribute(String span, String key, String value) {
    attributes[key] = value;
  }

  @override
  Future<void> destroy() async {}
  @override
  String get logTag => 'TestTelemetryService';
}
