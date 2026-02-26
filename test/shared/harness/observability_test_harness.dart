import 'dart:async';

import 'package:grumpy/grumpy.dart';

class RecordingTelemetryService extends TelemetryService {
  RecordingTelemetryService() : super.internal();

  int runSpanCalls = 0;
  final List<String> runSpanNames = <String>[];
  final Map<String, dynamic> spanAttributesMerged = <String, dynamic>{};
  final Map<String, Map<String, dynamic>?> spanAttributesByName =
      <String, Map<String, dynamic>?>{};
  final List<Object> recordedExceptions = <Object>[];

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
  }) async {
    runSpanCalls++;
    runSpanNames.add(name);
    if (attributes != null) {
      spanAttributesMerged.addAll(attributes);
    }
    spanAttributesByName[name] = attributes;
    return await callback();
  }

  @override
  void addSpanAttribute(String key, String value) {
    spanAttributesMerged[key] = value;
  }

  @override
  Future<void> destroy() async {}

  @override
  String get logTag => 'RecordingTelemetryService';
}

class RecordingAnalyticsService extends AnalyticsService {
  RecordingAnalyticsService() : super.internal();

  int trackEventCalls = 0;
  final List<String> trackedEventNames = <String>[];
  final List<Map<String, dynamic>?> trackedEventProperties =
      <Map<String, dynamic>?>[];
  final List<String> events = <String>[];
  final Map<String, Map<String, dynamic>?> eventProperties =
      <String, Map<String, dynamic>?>{};

  @override
  Future<void> trackEvent(
    String name, {
    Map<String, dynamic>? properties,
  }) async {
    trackEventCalls++;
    trackedEventNames.add(name);
    trackedEventProperties.add(properties);
    events.add(name);
    eventProperties[name] = properties;
  }

  @override
  Future<void> identifyUser(
    String userId, {
    Map<String, dynamic>? traits,
  }) async {}

  @override
  Future<void> recordNavigation(
    String from,
    String to, {
    Map<String, dynamic>? properties,
  }) async {}

  @override
  Future<void> recordPageView(
    String pageName, {
    Map<String, dynamic>? properties,
  }) async {}

  @override
  Future<void> groupUser(
    String groupId, {
    Map<String, dynamic>? traits,
  }) async {}

  @override
  Future<void> destroy() async {}

  @override
  String get logTag => 'RecordingAnalyticsService';
}
