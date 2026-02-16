// irrelevant for testing purposes
// ignore_for_file: missing_override_of_must_be_overridden

import 'package:logging/logging.dart';
import 'package:grumpy/grumpy.dart';
import 'package:test/test.dart';
import '../harness/telemetry_test_harness.dart';

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
        ownerType: TelemetryService,
      );

      expect(context.span, span);
      expect(context.attributes[#traceId], '123');
      expect(context.ownerType, TelemetryService);
    });
  });
  group('TelemetryZoneMixin', () {
    test('starts and ends spans around callbacks', () async {
      final service = TestTelemetryService();

      final result = await service.runSpan('span', () => 'value');

      expect(result, 'value');
      expect(service.startedSpans.single, 'span-span');
      expect(service.endedSpans.single, equals(('span-span', null)));
      expect(service.recordedExceptions, isEmpty);
    });

    test('propagates context for nested spans', () async {
      final service = TestTelemetryService();

      await service.runSpan('outer', () async {
        await service.runSpan('inner', () => null);
      });

      expect(service.parentSpans, contains('span-outer'));
      expect(service.startedSpans, containsAll(['span-outer', 'span-inner']));
    });

    test('delegates span attributes only when context exists', () async {
      final service = TestTelemetryService();

      await service.runSpan('attribute-span', () {
        service.addSpanAttribute('key', 'value');
      });

      expect(service.attributes, containsPair('key', 'value'));

      service.addSpanAttribute('key2', 'value2');
      expect(service.attributes.containsKey('key2'), isFalse);
    });
  });
}
