import 'dart:async';
import 'package:grumpy/grumpy.dart';

class TxRepo extends Repo<int>
    with
        RepoLifecycleMixin<int>,
        RepoLifecycleHooksMixin<int>,
        TelemetryMixin,
        TransactionalMutationMixin<int> {
  TxRepo() {
    installTransactionHooks();
  }

  @override
  String get logTag => 'TxRepo';
}

class UninstalledTxRepo extends Repo<int>
    with
        RepoLifecycleMixin<int>,
        RepoLifecycleHooksMixin<int>,
        TelemetryMixin,
        TransactionalMutationMixin<int> {
  @override
  String get logTag => 'UninstalledTxRepo';
}

class TestTelemetryService extends TelemetryService {
  TestTelemetryService() : super.internal();

  @override
  Future<T> runSpan<T>(
    String name,
    FutureOr<T> Function() operation, {
    Map<String, dynamic>? attributes,
  }) async {
    return await operation();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }

  @override
  String get logTag => 'TestTelemetryService';
}

class TestAnalyticsService extends AnalyticsService {
  TestAnalyticsService() : super.internal();

  @override
  Future<void> trackEvent(
    String name, {
    Map<String, dynamic>? properties,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return Future<void>.value();
  }

  @override
  String get logTag => 'TestAnalyticsService';
}
