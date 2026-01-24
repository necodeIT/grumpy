import 'package:grumpy/grumpy.dart';

/// A no-operation implementation of [AnalyticsService].
class NoopAnalyticsService extends AnalyticsService {
  @override
  noSuchMethod(Invocation invocation) {
    log('NoopAnalyticsService: ${invocation.memberName} called.');
  }

  @override
  String get logTag => 'NoopAnalyticsService';
}
