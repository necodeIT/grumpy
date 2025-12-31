import 'dart:async';

import 'package:logging/logging.dart';
import 'package:grumpy/grumpy.dart';
import 'package:test/test.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // this is not production code; it's just for test logging
    // ignore: avoid_print
    print(record);
  });
  group('TelemetryContext', () {
    test('stores span data and metadata', () {
      final attributes = <Symbol, dynamic>{#traceId: '123'};
      const span = 'fake-span';

      final context = TelemetryContext<String>(
        span: span,
        attributes: attributes,
        ownerType: _TelemetryService,
      );

      expect(context.span, span);
      expect(context.attributes[#traceId], '123');
      expect(context.ownerType, _TelemetryService);
    });
  });
  group('TelemetryZoneMixin', () {
    test('starts and ends spans around callbacks', () async {
      final service = _TestTelemetryService();

      final result = await service.runSpan('span', () => 'value');

      expect(result, 'value');
      expect(service.startedSpans.single, 'span-span');
      expect(service.endedSpans.single, equals(('span-span', null)));
      expect(service.recordedExceptions, isEmpty);
    });

    test('propagates context for nested spans', () async {
      final service = _TestTelemetryService();

      await service.runSpan('outer', () async {
        await service.runSpan('inner', () => null);
      });

      expect(service.parentSpans, contains('span-outer'));
      expect(service.startedSpans, containsAll(['span-outer', 'span-inner']));
    });

    test('delegates span attributes only when context exists', () async {
      final service = _TestTelemetryService();

      await service.runSpan('attribute-span', () {
        service.addSpanAttribute('key', 'value');
      });

      expect(service.attributes, containsPair('key', 'value'));

      service.addSpanAttribute('key2', 'value2');
      expect(service.attributes.containsKey('key2'), isFalse);
    });
  });
}

class _TestTelemetryService extends TelemetryService
    with TelemetryZoneMixin<String> {
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
  Future<void> dispose() async {}
}

class _TelemetryService {}
