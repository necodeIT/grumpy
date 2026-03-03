import 'package:grumpy/grumpy.dart';

/// A no-operation implementation of [AnalyticsService].
///
/// {@category telemetry}

class NoopAnalyticsService extends AnalyticsService {
  /// A no-operation implementation of [AnalyticsService].
  NoopAnalyticsService() : super.internal();

  @override
  noSuchMethod(Invocation invocation) {
    log('NoopAnalyticsService: ${invocation.memberName} called.');
  }

  @override
  String get logTag => 'NoopAnalyticsService';
}
