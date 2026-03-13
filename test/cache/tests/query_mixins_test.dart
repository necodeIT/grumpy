// irrelevant for testing purposes
// ignore_for_file: missing_override_of_must_be_overridden
import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:grumpy/grumpy.dart';
import 'package:grumpy/src/cache/infra/services/default_cache_pipeline_service.dart';
import 'package:test/test.dart';
import '../harness/query_mixins_test_harness.dart';
import '../harness/test_item_codecs.dart';

void main() {
  final di = GetIt.instance;
  late TestTelemetryService telemetry;
  late TestAnalyticsService analytics;
  final repos = <Repo<List<TestItem>>>[];

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // this is not production code; it's just for test logging
    // ignore: avoid_print
    print(record);
  });

  TestQueryRepo createRepo({
    bool? invalidateOnNewData,
    bool? invalidateOnError,
    bool? invalidateOnLoading,
    bool? cacheNullResults,
  }) {
    final repo = TestQueryRepo(
      invalidateOnNewData: invalidateOnNewData,
      invalidateOnError: invalidateOnError,
      invalidateOnLoading: invalidateOnLoading,
      cacheNullResults: cacheNullResults,
    );
    repos.add(repo);
    return repo;
  }

  UninitializedQueryRepo createUninitializedRepo() {
    final repo = UninitializedQueryRepo();
    repos.add(repo);
    return repo;
  }

  setUp(() async {
    await di.reset();
    telemetry = TestTelemetryService();
    analytics = TestAnalyticsService();
    di.registerSingleton<AnalyticsService>(analytics);
    di.registerSingleton<TelemetryService>(telemetry);
    di.registerSingleton<CachePipelineService>(
      DefaultCachePipelineService(memoryLayer: TestMemoryCacheLayer()),
    );
  });

  tearDown(() async {
    for (final repo in repos) {
      await repo.destroy();
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
        queryParams: const {'cacheKey': 'count'},
        codec: const IntegerCodec(),
      );

      expect(result, isNull);
      expect(telemetry.runSpanCalls, 0);
    });

    test('caches results and invalidates when data changes', () async {
      final repo = createRepo()..setItems(seedItems);
      var computeCalls = 0;

      FutureOr<int> compute(List<TestItem> items) {
        computeCalls++;
        return items.length;
      }

      final first = await repo.query<int>(
        'countItems',
        compute,
        queryParams: const {'cacheKey': 'count'},
        codec: const IntegerCodec(),
      );

      final second = await repo.query<int>(
        'countItems',
        compute,
        queryParams: const {'cacheKey': 'count'},
        codec: const IntegerCodec(),
      );

      repo.setItems([
        ...seedItems,
        const TestItem(
          id: '3',
          name: 'Golden Pear',
          description: 'A ripe pear with golden skin.',
        ),
      ]);

      final third = await repo.query<int>(
        'countItems',
        compute,
        queryParams: const {'cacheKey': 'count'},
        codec: const IntegerCodec(),
      );

      expect(first, equals(2));
      expect(second, equals(2));
      expect(third, equals(3));
      expect(computeCalls, 2);
      expect(telemetry.runSpanCalls, 2);
    });

    test('caches null results when enabled', () async {
      final repo = createRepo()..setItems(seedItems);
      var computeCalls = 0;

      FutureOr<TestItem?> compute(List<TestItem> items) {
        computeCalls++;
        return null;
      }

      final first = await repo.query<TestItem?>(
        'findMissing',
        compute,
        queryParams: const {'cacheKey': 'missing'},
        codec: const TestItemCodec(),
      );

      final second = await repo.query<TestItem?>(
        'findMissing',
        compute,
        queryParams: const {'cacheKey': 'missing'},
        codec: const TestItemCodec(),
      );

      expect(first, isNull);
      expect(second, isNull);
      expect(computeCalls, 1);
    });

    test('skips caching null results when disabled', () async {
      final repo = createRepo(cacheNullResults: false)..setItems(seedItems);
      var computeCalls = 0;

      FutureOr<TestItem?> compute(List<TestItem> items) {
        computeCalls++;
        return null;
      }

      await repo.query<TestItem?>(
        'findMissing',
        compute,
        queryParams: const {'cacheKey': 'missing'},
        codec: const TestItemCodec(),
      );

      await repo.query<TestItem?>(
        'findMissing',
        compute,
        queryParams: const {'cacheKey': 'missing'},
        codec: const TestItemCodec(),
      );

      expect(computeCalls, 2);
      expect(telemetry.runSpanCalls, 2);
    });

    test('asserts when installMemoryCacheHooks was not called', () async {
      final repo = createUninitializedRepo()..setItems(seedItems);

      expect(
        () => repo.query<int>(
          'countItems',
          (items) => items.length,
          codec: const IntegerCodec(),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('QueryByIdMixin', () {
    test('returns matching item and caches the result', () async {
      final repo = createRepo()..setItems(seedItems);

      final first = await repo.getById('1', codec: const TestItemCodec());
      final second = await repo.getById('1', codec: const TestItemCodec());

      expect(first, isNotNull);
      expect(first?.name, equals('Red Apple'));
      expect(second, same(first));
      expect(telemetry.runSpanCalls, 1);
      expect(telemetry.runSpanNames, contains('queryById'));
    });

    test('returns null for missing item and caches the lookup', () async {
      final repo = createRepo()..setItems(seedItems);

      final first = await repo.getById('missing', codec: const TestItemCodec());
      final second = await repo.getById(
        'missing',
        codec: const TestItemCodec(),
      );

      expect(first, isNull);
      expect(second, isNull);
      expect(telemetry.runSpanCalls, 1);
      expect(telemetry.runSpanNames, contains('queryById'));
    });
  });

  group('FuzzyFindQueryMixin', () {
    test('performs fuzzy search and caches by query params key', () async {
      final repo = createRepo()..setItems(seedItems);

      final first = await repo.fuzzyFind(
        'rd apple',
        codec: const TestItemListCodec(),
      );

      final second = await repo.fuzzyFind(
        'rd apple',
        codec: const TestItemListCodec(),
      );

      expect(first, hasLength(1));
      expect(first.first.name, equals('Red Apple'));
      expect(second, same(first));
      expect(telemetry.runSpanCalls, 1);
      expect(telemetry.runSpanNames, contains('fuzzyFind'));
    });
  });

  group('Analytics and Telemetry', () {
    test('records analytics events', () async {
      final repo = createRepo()..setItems(seedItems);

      await repo.getById(
        '1',
        analyticsAction: 'getItemById',
        analyticsProperties: {'source': 'test'},
        codec: const TestItemCodec(),
      );
      expect(analytics.trackEventCalls, 1);
      expect(analytics.trackedEventNames, contains('getItemById'));
      expect(
        analytics.trackedEventProperties.first,
        containsPair('source', 'test'),
      );
    });

    test('records telemetry spans', () async {
      final repo = createRepo()..setItems(seedItems);

      await repo.fuzzyFind(
        'blue',
        analyticsAction: 'fuzzySearch',
        analyticsProperties: {'source': 'test'},
        codec: const TestItemListCodec(),
      );

      expect(telemetry.runSpanCalls, 1);
      expect(telemetry.runSpanNames, contains('fuzzyFind'));
      expect(telemetry.spanAttributes, containsPair('query', 'blue'));
    });
  });
}
