import 'package:grumpy/grumpy.dart';
import '../../shared/harness/harness.dart';

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

class TestTelemetryService extends RecordingTelemetryService {
  @override
  String get logTag => 'TestTelemetryService';
}

class TestAnalyticsService extends RecordingAnalyticsService {
  @override
  String get logTag => 'TestAnalyticsService';
}
