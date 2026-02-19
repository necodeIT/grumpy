import 'package:grumpy/grumpy.dart';
import '../../shared/harness/harness.dart';

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

class TestTelemetry extends RecordingTelemetryService {
  Map<String, Map<String, dynamic>?> get spanAttributes => spanAttributesByName;

  @override
  String get logTag => 'TestTelemetry';
}

class TestAnalytics extends RecordingAnalyticsService {
  @override
  String get logTag => 'TestAnalytics';
}
