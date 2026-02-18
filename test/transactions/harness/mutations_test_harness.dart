import 'dart:async';
import 'package:grumpy/grumpy.dart';

class MutationRepo extends Repo<int>
    with
        RepoLifecycleMixin<int>,
        RepoLifecycleHooksMixin<int>,
        TelemetryMixin,
        /// This is a test case. we will remove this mixin once TransactionalMutationMixin is feature complete.
        // ignore: deprecated_member_use_from_same_package
        MutationMixins<int> {
  MutationRepo() {
    installMutationHooks();
  }

  @override
  Future<void> activate() async {}

  @override
  Future<void> deactivate() async {}

  @override
  Future<void> dependenciesChanged() async {}

  @override
  Future<void> initialize() async {
    await super.initialize();
  }

  @override
  Future<void> free() async {
    await super.free();
  }

  @override
  String get logTag => 'MutationRepo';
}

// for testing uninitialized repo behavior
// ignore: missing_required_constructor_call
class UninitializedMutationRepo extends Repo<int>
    with
        RepoLifecycleMixin<int>,
        RepoLifecycleHooksMixin<int>,
        TelemetryMixin,
        /// This is a test case. we will remove this mixin once TransactionalMutationMixin is feature complete.
        // ignore: deprecated_member_use_from_same_package
        MutationMixins<int> {
  @override
  Future<void> activate() async {}

  @override
  Future<void> deactivate() async {}

  @override
  Future<void> dependenciesChanged() async {}

  @override
  Future<void> initialize() async {
    await super.initialize();
  }

  @override
  Future<void> free() async {
    await super.free();
  }

  @override
  String get logTag => 'UninitializedMutationRepo';
}

class TestTelemetry extends TelemetryService {
  TestTelemetry() : super.internal();

  final List<String> runSpanNames = [];
  final Map<String, Map<String, dynamic>?> spanAttributes = {};

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
  ]) async {}

  @override
  Future<T> runSpan<T>(
    String name,
    FutureOr<T> Function() callback, {
    Map<String, dynamic>? attributes,
  }) async {
    runSpanNames.add(name);
    spanAttributes[name] = attributes;
    return await callback();
  }

  @override
  void addSpanAttribute(String key, String value) {}

  @override
  Future<void> free() async {}
  @override
  String get logTag => 'TestTelemetry';
}

class TestAnalytics extends AnalyticsService {
  TestAnalytics() : super.internal();

  final List<String> events = [];
  final Map<String, Map<String, dynamic>?> eventProperties = {};

  @override
  Future<void> trackEvent(
    String name, {
    Map<String, dynamic>? properties,
  }) async {
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
  Future<void> free() async {}
  @override
  String get logTag => 'TestAnalytics';
}
