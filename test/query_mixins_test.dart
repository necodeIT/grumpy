import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:grumpy/grumpy.dart';
import 'package:test/test.dart';

void main() {
  final di = GetIt.instance;
  late _TestTelemetryService telemetry;
  late _TestAnalyticsService analytics;
  final repos = <Repo<List<_TestItem>>>[];

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // this is not production code; it's just for test logging
    // ignore: avoid_print
    print(record);
  });

  _TestQueryRepo createRepo({
    bool? invalidateOnNewData,
    bool? invalidateOnError,
    bool? invalidateOnLoading,
    bool? cacheNullResults,
  }) {
    final repo = _TestQueryRepo(
      invalidateOnNewData: invalidateOnNewData,
      invalidateOnError: invalidateOnError,
      invalidateOnLoading: invalidateOnLoading,
      cacheNullResults: cacheNullResults,
    );
    repos.add(repo);
    return repo;
  }

  _UninitializedQueryRepo createUninitializedRepo() {
    final repo = _UninitializedQueryRepo();
    repos.add(repo);
    return repo;
  }

  setUp(() async {
    await di.reset();
    telemetry = _TestTelemetryService();
    analytics = _TestAnalyticsService();
    di.registerSingleton<AnalyticsService>(analytics);
    di.registerSingleton<TelemetryService>(telemetry);
  });

  tearDown(() async {
    for (final repo in repos) {
      await repo.free();
    }
    repos.clear();
    await di.reset();
  });

  group('QueryMixin', () {
    test('returns null when no data is available', () async {
      final repo = createRepo();

      final result = await repo.query<int>(
        'countItems',
        (data) => data.length,
        cacheKey: 'count',
      );

      expect(result, isNull);
      expect(telemetry.runSpanCalls, 0);
    });

    test('caches results and invalidates when data changes', () async {
      final repo = createRepo()..setItems(_seedItems);
      var computeCalls = 0;

      FutureOr<int> compute(List<_TestItem> items) {
        computeCalls++;
        return items.length;
      }

      final first = await repo.query<int>(
        'countItems',
        compute,
        cacheKey: 'count',
      );

      final second = await repo.query<int>(
        'countItems',
        compute,
        cacheKey: 'count',
      );

      repo.setItems([
        ..._seedItems,
        const _TestItem(
          id: '3',
          name: 'Golden Pear',
          description: 'A ripe pear with golden skin.',
        ),
      ]);

      final third = await repo.query<int>(
        'countItems',
        compute,
        cacheKey: 'count',
      );

      expect(first, equals(2));
      expect(second, equals(2));
      expect(third, equals(3));
      expect(computeCalls, 2);
      expect(telemetry.runSpanCalls, 2);
    });

    test('caches null results when enabled', () async {
      final repo = createRepo()..setItems(_seedItems);
      var computeCalls = 0;

      FutureOr<_TestItem?> compute(List<_TestItem> items) {
        computeCalls++;
        return null;
      }

      final first = await repo.query<_TestItem?>(
        'findMissing',
        compute,
        cacheKey: 'missing',
      );

      final second = await repo.query<_TestItem?>(
        'findMissing',
        compute,
        cacheKey: 'missing',
      );

      expect(first, isNull);
      expect(second, isNull);
      expect(computeCalls, 1);
    });

    test('skips caching null results when disabled', () async {
      final repo = createRepo(cacheNullResults: false)..setItems(_seedItems);
      var computeCalls = 0;

      FutureOr<_TestItem?> compute(List<_TestItem> items) {
        computeCalls++;
        return null;
      }

      await repo.query<_TestItem?>('findMissing', compute, cacheKey: 'missing');

      await repo.query<_TestItem?>('findMissing', compute, cacheKey: 'missing');

      expect(computeCalls, 2);
      expect(telemetry.runSpanCalls, 2);
    });

    test('asserts when installMemoryCacheHooks was not called', () async {
      final repo = createUninitializedRepo()..setItems(_seedItems);

      expect(
        () => repo.query<int>('countItems', (items) => items.length),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('QueryByIdMixin', () {
    test('returns matching item and caches the result', () async {
      final repo = createRepo()..setItems(_seedItems);

      final first = await repo.getById('1');
      final second = await repo.getById('1');

      expect(first, isNotNull);
      expect(first?.name, equals('Red Apple'));
      expect(second, same(first));
      expect(telemetry.runSpanCalls, 1);
      expect(telemetry.runSpanNames, contains('queryById'));
    });

    test('returns null for missing item and caches the lookup', () async {
      final repo = createRepo()..setItems(_seedItems);

      final first = await repo.getById('missing');
      final second = await repo.getById('missing');

      expect(first, isNull);
      expect(second, isNull);
      expect(telemetry.runSpanCalls, 1);
      expect(telemetry.runSpanNames, contains('queryById'));
    });
  });

  group('FuzzyFindQueryMixin', () {
    test('performs fuzzy search and caches by normalized key', () async {
      final repo = createRepo()..setItems(_seedItems);

      final first = await repo.fuzzyFind('rd apple');

      final second = await repo.fuzzyFind('RD APPLE');

      expect(first, hasLength(1));
      expect(first.first.name, equals('Red Apple'));
      expect(second, same(first));
      expect(telemetry.runSpanCalls, 1);
      expect(telemetry.runSpanNames, contains('fuzzyFind'));
    });
  });

  group('Analytics and Telemetry', () {
    test('records analytics events', () async {
      final repo = createRepo()..setItems(_seedItems);

      await repo.getById(
        '1',
        analyticsAction: 'getItemById',
        analyticsProperties: {'source': 'test'},
      );
      expect(analytics.trackEventCalls, 1);
      expect(analytics.trackedEventNames, contains('getItemById'));
      expect(
        analytics.trackedEventProperties.first,
        containsPair('source', 'test'),
      );
    });

    test('records telemetry spans', () async {
      final repo = createRepo()..setItems(_seedItems);

      await repo.fuzzyFind(
        'blue',
        analyticsAction: 'fuzzySearch',
        analyticsProperties: {'source': 'test'},
      );

      expect(telemetry.runSpanCalls, 1);
      expect(telemetry.runSpanNames, contains('fuzzyFind'));
      expect(telemetry.spanAttributes, containsPair('query', 'blue'));
    });
  });
}

class _TestQueryRepo extends Repo<List<_TestItem>>
    with
        RepoLifecycleMixin<List<_TestItem>>,
        RepoLifecycleHooksMixin<List<_TestItem>>,
        TelemetryMixin,
        QueryMixin<List<_TestItem>>,
        QueryByIdMixin<_TestItem, String>,
        FuzzyFindQueryMixin<_TestItem> {
  _TestQueryRepo({
    bool? invalidateOnNewData,
    bool? invalidateOnError,
    bool? invalidateOnLoading,
    bool? cacheNullResults,
  }) : _invalidateOnNewData = invalidateOnNewData,
       _invalidateOnError = invalidateOnError,
       _invalidateOnLoading = invalidateOnLoading,
       _cacheNullResults = cacheNullResults {
    installMemoryCacheHooks();

    initialize();
  }

  final bool? _invalidateOnNewData;
  final bool? _invalidateOnError;
  final bool? _invalidateOnLoading;
  final bool? _cacheNullResults;

  void setItems(List<_TestItem> items) => data(items);

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
  List<String Function(_TestItem item)> get fuzzySelectors => [
    (item) => item.name,
    (item) => item.description,
  ];

  @override
  String getId(_TestItem item) => item.id;
}

class _UninitializedQueryRepo extends Repo<List<_TestItem>>
    with
        RepoLifecycleMixin<List<_TestItem>>,
        RepoLifecycleHooksMixin<List<_TestItem>>,
        TelemetryMixin,
        QueryMixin<List<_TestItem>>,
        QueryByIdMixin<_TestItem, String> {
  void setItems(List<_TestItem> items) => data(items);

  @override
  String getId(_TestItem item) => item.id;
}

class _TestTelemetryService extends TelemetryService {
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
}

class _TestItem {
  const _TestItem({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;
}

final _seedItems = <_TestItem>[
  const _TestItem(
    id: '1',
    name: 'Red Apple',
    description: 'A crisp red apple from the orchard.',
  ),
  const _TestItem(
    id: '2',
    name: 'Blue Berry',
    description: 'Fresh blueberries picked at dawn.',
  ),
];

class _TestAnalyticsService extends AnalyticsService {
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
}
