import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fuzzy_bolt/fuzzy_bolt.dart';
import 'package:get_it/get_it.dart';
import 'package:grumpy_annotations/grumpy_annotations.dart';
import 'package:memory_cache/memory_cache.dart';
import 'package:meta/meta.dart';
import 'package:grumpy/grumpy.dart';

/// Adds query execution with telemetry and optional cache-pipeline support.
///
/// [QueryMixin] keeps read-path logic in repos ergonomic while providing:
/// - trace spans for each query execution
/// - optional analytics events
/// - in-flight deduplication per cache key
/// - legacy in-memory caching fallback
/// - optional multi-layer pipeline caching (memory + file)
///
/// Setup:
/// 1. mix into a repo that includes [RepoLifecycleHooksMixin].
/// 2. call [installMemoryCacheHooks] in the repo constructor.
/// 3. call [query] from domain-specific read methods.
///
/// Example:
/// ```dart
/// Future<User?> getById(String id) {
///   return query<User?>(
///     'getUserById',
///     (data) => data.firstWhere((u) => u.id == id),
///     cacheKey: id,
///     ttl: const Duration(minutes: 2),
///   );
/// }
/// ```
///
/// {@category cache}

mixin QueryMixin<T> on Repo<T>, RepoLifecycleHooksMixin<T>, TelemetryMixin {
  bool _installed = false;

  int _dataVersion = 0;

  /// Legacy in-memory cache used when pipeline is unavailable.
  final cache = MemoryCache();
  final Map<StorageKey, Future<Object?>> _inflight =
      <StorageKey, Future<Object?>>{};

  /// Default cache expiration for legacy memory-cache mode.
  ///
  /// Used only when pipeline integration is not active.
  Duration get cacheExpiry => const Duration(minutes: 5);

  /// Clears cache when repo emits new data.
  bool get invalidateCacheOnNewData => true;

  /// Clears cache when repo emits error.
  bool get invalidateCacheOnError => true;

  /// Clears cache when repo emits loading.
  bool get invalidateCacheOnLoading => true;

  /// Caches `null` query results in legacy mode.
  bool get cacheNullResults => true;

  /// Namespace used when pipeline-backed keys are built.
  ///
  /// Defaults to 'cache/repo-name'.
  String get cacheNamespace => 'cache/$logTag';

  /// Default cache policy used when no per-query policy is supplied.
  CachePolicy<Uint8List> get defaultCachePolicy =>
      const CachePolicy<Uint8List>();

  /// Enables cache pipeline integration when service is registered.
  bool get enableCachePipeline => true;

  StorageKey _buildStorageKey(String name, Map<String, dynamic>? queryParams) {
    final jsonStr = jsonEncode({
      'name': name,
      'dataVersion': _dataVersion,
      'queryParams': queryParams,
    });
    final bytes = utf8.encode(jsonStr);
    final key = base64Url.encode(bytes);

    return StorageKey(
      namespace: cacheNamespace,
      primaryKey: key,
      schemaId: 'query_mixin_v1',
    );
  }

  /// Installs query cache lifecycle hooks.
  ///
  /// Must be called in the repo constructor.
  /// Hook behavior:
  /// - increments data version on each `data(...)` emission
  /// - optionally invalidates legacy cache on data/error/loading transitions
  /// - clears cache on dispose
  @nonVirtual
  @mustCallInConstructor
  void installMemoryCacheHooks() {
    if (_installed) return;

    onData((_) {
      _dataVersion++;
      if (invalidateCacheOnNewData) {
        cache.invalidate();
        log('Cache cleared due to new data. (v=$_dataVersion)');
      }
    });

    onLoading(() {
      if (invalidateCacheOnLoading) {
        cache.invalidate();
        log('Cache cleared due to loading state.');
      }
    });

    onError((error, stackTrace) {
      if (invalidateCacheOnError) {
        cache.invalidate();
        log('Cache cleared due to error: $error');
      }
    });

    onDisposed(() {
      cache.invalidate();
      log('Cache cleared on dispose.');
    });

    _installed = true;
  }

  /// Executes a query with telemetry, optional analytics, and cache lookups.
  ///
  /// Execution order:
  /// 1. validate setup and data availability
  /// 2. deduplicate concurrent identical queries
  /// 3. attempt cache read (pipeline or legacy memory)
  /// 4. execute callback on miss/stale-refresh path
  /// 5. write-through result according to policy
  ///
  /// Returns:
  /// - query value when available
  /// - `null` when no data, cache miss + callback failure, or callback returns
  ///   null for nullable result types.
  Future<QueryResult?> query<QueryResult>(
    String name,
    FutureOr<QueryResult> Function(T data) query, {
    Map<String, dynamic>? queryParams,
    CachePolicy<Uint8List>? cachePolicy,
    required SerializationCodec<QueryResult, Uint8List> codec,
    Duration? ttl,
    Map<String, String>? telemetryAttributes,
    String? analyticsAction,
    Map<String, String>? analyticsProperties,
  }) async {
    if (!_installed) {
      throw StateError(
        'QueryMixin not installed. Call installMemoryCacheHooks in the Repo constructor.',
      );
    }
    if (name.isEmpty) {
      throw ArgumentError.value(
        name,
        'name',
        'QueryMixin: Query name must not be empty.',
      );
    }

    if (analyticsAction != null) {
      await AnalyticsService().trackEvent(
        analyticsAction,
        properties: analyticsProperties,
      );
    }

    if (!state.hasData) {
      log('$name: Aborting query - no data available');
      return null;
    }

    final key = _buildStorageKey(name, queryParams);

    final pending = _inflight[key];
    if (pending != null) {
      return await pending as QueryResult?;
    }

    final future = _queryInternal<QueryResult>(
      name,
      query,
      key: key,
      cachePolicy: cachePolicy ?? defaultCachePolicy,
      codec: codec,
      telemetryAttributes: telemetryAttributes,
    );

    _inflight[key] = future;
    try {
      return await future;
    } finally {
      await _inflight.remove(key);
    }
  }

  Future<QueryResult?> _queryInternal<QueryResult>(
    String name,
    FutureOr<QueryResult> Function(T data) query, {
    required StorageKey key,
    required CachePolicy<Uint8List> cachePolicy,
    required SerializationCodec<QueryResult, Uint8List> codec,
    required Map<String, String>? telemetryAttributes,
  }) async {
    final pipeline = _resolvePipeline();

    QueryResult? staleFallback;

    if (pipeline != null) {
      final cached = await pipeline.get<QueryResult>(
        key: key,
        policy: cachePolicy,
        codec: codec,
      );

      if (cached != null) {
        if (!cached.isStale) {
          return cached.value;
        }
        staleFallback = cached.value;
      }

      try {
        final result = await trace(
          name,
          () => query(state.requireData),
          attributes: telemetryAttributes,
        );
        await pipeline.put<QueryResult>(
          key,
          result,
          policy: cachePolicy,
          codec: codec,
        );
        return result;
      } catch (e, st) {
        log('$name: Error during query execution', e, st);
        if (staleFallback != null && cachePolicy.allowStaleFileOnQueryError) {
          return staleFallback;
        }
        return null;
      }
    }

    QueryResult? result;
    try {
      result = await trace(
        name,
        () => query(state.requireData),
        attributes: telemetryAttributes,
      );
    } catch (e, st) {
      log('$name: Error during query execution', e, st);
      result = null;
    }

    return result;
  }

  CachePipelineService? _resolvePipeline() {
    if (!enableCachePipeline) return null;
    if (!GetIt.I.isRegistered<CachePipelineService>()) return null;
    return CachePipelineService();
  }
}

/// Adds convenience ID-based query lookup behavior.
///
/// Useful for list-backed repos where items have stable identifiers.
///
/// {@category cache}

mixin QueryByIdMixin<T, ID> on Repo<List<T>>, QueryMixin<List<T>> {
  /// Returns an item by [id], or `null` when not found.
  Future<T?> getById(
    ID id, {
    String? analyticsAction,
    Map<String, dynamic>? analyticsProperties,
    CachePolicy<Uint8List>? cachePolicy,
    required SerializationCodec<T, Uint8List> codec,
  }) async {
    return query<T?>(
      'queryById',
      (data) {
        try {
          return data.firstWhere((item) => getId(item) == id);
        } catch (_) {
          log('Item with ID $id not found.');
          return null;
        }
      },
      queryParams: {'id': id.toString()},
      telemetryAttributes: {'id': id.toString()},
      analyticsAction: analyticsAction,
      cachePolicy: cachePolicy,
      codec: codec,
      analyticsProperties: {
        'id': id.toString(),
        ...?analyticsProperties?.map((k, v) => MapEntry(k, '$v')),
      },
    );
  }

  /// Returns the stable identifier for [item].
  ID getId(T item);
}

/// Adds fuzzy-search query helpers for list-backed repos.
///
/// This mixin delegates scoring to `fuzzy_bolt` and keeps caching/telemetry
/// behavior consistent with [QueryMixin.query].
///
/// {@category cache}

mixin FuzzyFindQueryMixin<T> on Repo<List<T>>, QueryMixin<List<T>> {
  /// Performs a fuzzy search and returns ranked results.
  Future<List<T>> fuzzyFind(
    String query, {
    String? analyticsAction,
    Map<String, dynamic>? analyticsProperties,
    CachePolicy<Uint8List>? cachePolicy,
    required SerializationCodec<List<T>, Uint8List> codec,
  }) async {
    final result = await this.query<List<T>>(
      'fuzzyFind',
      (data) async {
        final r = await FuzzyBolt.searchWithConfig<T>(
          data,
          query,
          fuzzySelectors,
          fuzzySearchConfig,
        );

        return r.map<T>(extractResult).toList();
      },
      queryParams: {'fuzzy_query': query},
      telemetryAttributes: {'query': query},
      cachePolicy: cachePolicy,
      codec: codec,
      analyticsAction: analyticsAction,
      analyticsProperties: {
        'query': query,
        ...?analyticsProperties?.map((k, v) => MapEntry(k, '$v')),
      },
    );

    return result ?? <T>[];
  }

  /// Selectors used for fuzzy search matching.
  List<String Function(T item)> get fuzzySelectors;

  /// Search configuration used by the fuzzy engine.
  FuzzySearchConfig get fuzzySearchConfig => const FuzzySearchConfig();

  /// Maps a fuzzy result into the caller's item type.
  T extractResult(FuzzyResult<T> result) => result.item;
}
