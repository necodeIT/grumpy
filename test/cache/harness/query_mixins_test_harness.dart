import 'package:grumpy/grumpy.dart';
import '../../shared/harness/harness.dart';

class TestQueryRepo extends Repo<List<TestItem>>
    with
        RepoLifecycleMixin<List<TestItem>>,
        RepoLifecycleHooksMixin<List<TestItem>>,
        TelemetryMixin,
        QueryMixin<List<TestItem>>,
        QueryByIdMixin<TestItem, String>,
        FuzzyFindQueryMixin<TestItem> {
  TestQueryRepo({
    bool? invalidateOnNewData,
    bool? invalidateOnError,
    bool? invalidateOnLoading,
    bool? cacheNullResults,
  }) : _invalidateOnNewData = invalidateOnNewData,
       _invalidateOnError = invalidateOnError,
       _invalidateOnLoading = invalidateOnLoading,
       _cacheNullResults = cacheNullResults {
    installMemoryCacheHooks();
  }

  final bool? _invalidateOnNewData;
  final bool? _invalidateOnError;
  final bool? _invalidateOnLoading;
  final bool? _cacheNullResults;

  void setItems(List<TestItem> items) => data(items);

  @override
  bool get invalidateCacheOnNewData =>
      _invalidateOnNewData ?? super.invalidateCacheOnNewData;

  @override
  bool get invalidateCacheOnError =>
      _invalidateOnError ?? super.invalidateCacheOnError;

  @override
  bool get invalidateCacheOnLoading =>
      _invalidateOnLoading ?? super.invalidateCacheOnLoading;

  @override
  bool get cacheNullResults => _cacheNullResults ?? super.cacheNullResults;

  @override
  List<String Function(TestItem item)> get fuzzySelectors => [
    (item) => item.name,
    (item) => item.description,
  ];

  @override
  String getId(TestItem item) => item.id;
  @override
  String get logTag => 'TestQueryRepo';
}

// for testing uninitialized repo behavior
// ignore: missing_required_constructor_call
class UninitializedQueryRepo extends Repo<List<TestItem>>
    with
        RepoLifecycleMixin<List<TestItem>>,
        RepoLifecycleHooksMixin<List<TestItem>>,
        TelemetryMixin,
        QueryMixin<List<TestItem>>,
        QueryByIdMixin<TestItem, String> {
  void setItems(List<TestItem> items) => data(items);

  @override
  String getId(TestItem item) => item.id;
  @override
  String get logTag => 'UninitializedQueryRepo';
}

class TestTelemetryService extends RecordingTelemetryService {
  Map<String, dynamic> get spanAttributes => spanAttributesMerged;

  @override
  String get logTag => 'TestTelemetryService';
}

class TestItem {
  const TestItem({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;
}

final seedItems = <TestItem>[
  const TestItem(
    id: '1',
    name: 'Red Apple',
    description: 'A crisp red apple from the orchard.',
  ),
  const TestItem(
    id: '2',
    name: 'Blue Berry',
    description: 'Fresh blueberries picked at dawn.',
  ),
];

class TestAnalyticsService extends RecordingAnalyticsService {
  @override
  String get logTag => 'TestAnalyticsService';
}
