import 'dart:typed_data';

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
  CachePolicy<Uint8List> get defaultCachePolicy =>
      CachePolicy<Uint8List>(cacheNullResults: cacheNullResults);

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

class TestMemoryCacheLayer extends MemoryCacheLayerService {
  TestMemoryCacheLayer() : super.internal();

  final Map<String, CacheEntry<Object?>> _entries =
      <String, CacheEntry<Object?>>{};

  @override
  Future<CacheEntry<T>?> read<T>(
    StorageKey key, {
    SerializationCodec<T, Uint8List>? codec,
  }) async {
    final entry = _entries[key.asStorageKey()];
    if (entry == null) return null;

    return CacheEntry<T>(
      value: entry.value as T,
      createdAt: entry.createdAt,
      expiresAt: entry.expiresAt,
    );
  }

  @override
  Future<void> write<T>(
    StorageKey key,
    CacheEntry<T> entry, {
    SerializationCodec<T, Uint8List>? codec,
  }) async {
    _entries[key.asStorageKey()] = CacheEntry<Object?>(
      value: entry.value,
      createdAt: entry.createdAt,
      expiresAt: entry.expiresAt,
    );
  }

  @override
  Future<void> invalidate<T>(StorageKey key) async {
    _entries.remove(key.asStorageKey());
  }

  @override
  Future<void> clearNamespace(String namespace) async {
    _entries.removeWhere((encodedKey, _) {
      final parsed = StorageKey.parseOrNull(encodedKey);
      return parsed?.namespace == namespace;
    });
  }

  @override
  Future<void> destroy() async {
    _entries.clear();
  }

  @override
  String get logTag => 'TestMemoryCacheLayer';
}
