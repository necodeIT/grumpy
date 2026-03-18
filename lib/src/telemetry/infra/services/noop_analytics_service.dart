import 'dart:async';

import 'package:grumpy/grumpy.dart';

/// A no-operation implementation of [AnalyticsService].
///
/// {@category telemetry}

class NoopAnalyticsService extends AnalyticsService {
  /// A no-operation implementation of [AnalyticsService].
  NoopAnalyticsService() : super.internal();

  @override
  String get logTag => 'NoopAnalyticsService';

  @override
  FutureOr<void> destroy() {}

  @override
  Future<void> groupUser(String groupId, {Map<String, dynamic>? traits}) async {
    log('groupUser called.');
  }

  @override
  Future<void> identifyUser(
    String userId, {
    Map<String, dynamic>? traits,
  }) async {
    log('identifyUser called.');
  }

  @override
  Future<void> recordNavigation(
    String from,
    String to, {
    Map<String, dynamic>? properties,
  }) async {
    log('recordNavigation called.');
  }

  @override
  Future<void> recordPageView(
    String pageName, {
    Map<String, dynamic>? properties,
  }) async {
    log('recordPageView called.');
  }

  @override
  Future<void> trackEvent(
    String name, {
    Map<String, dynamic>? properties,
  }) async {
    log('trackEvent called.');
  }
}
