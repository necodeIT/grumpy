import 'dart:async';
import 'package:grumpy/grumpy.dart';

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

class TestTelemetryService extends TelemetryService {
  TestTelemetryService() : super.internal();

  int runSpanCalls = 0;
  final List<String> runSpanNames = [];
  final Map<String, dynamic> spanAttributes = {};

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
    runSpanCalls++;
    runSpanNames.add(name);
    if (attributes != null) {
      spanAttributes.addAll(attributes);
    }

    return await callback();
  }

  @override
  void addSpanAttribute(String key, String value) {
    spanAttributes[key] = value;
  }

  @override
  FutureOr<void> free() {}
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

class TestAnalyticsService extends AnalyticsService {
  TestAnalyticsService() : super.internal();

  int trackEventCalls = 0;
  final List<String> trackedEventNames = [];
  final List<Map<String, dynamic>?> trackedEventProperties = [];

  @override
  FutureOr<void> free() {}

  @override
  Future<void> groupUser(String groupId, {Map<String, dynamic>? traits}) {
    throw UnimplementedError();
  }

  @override
  Future<void> identifyUser(String userId, {Map<String, dynamic>? traits}) {
    throw UnimplementedError();
  }

  @override
  Future<void> recordNavigation(
    String from,
    String to, {
    Map<String, dynamic>? properties,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> recordPageView(
    String pageName, {
    Map<String, dynamic>? properties,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> trackEvent(
    String name, {
    Map<String, dynamic>? properties,
  }) async {
    trackEventCalls++;
    trackedEventNames.add(name);
    trackedEventProperties.add(properties);
  }

  @override
  String get logTag => 'TestAnalyticsService';
}
