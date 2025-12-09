import 'dart:async';

import 'package:fuzzy_bolt/fuzzy_bolt.dart';
import 'package:memory_cache/memory_cache.dart';
import 'package:meta/meta.dart';
import 'package:modular_foundation/annotations.dart';
import 'package:modular_foundation/modular_foundation.dart';

/// Adds query execution with telemetry and in-memory caching to a [Repo].
mixin QueryMixin<T> on Repo<T>, RepoLifecycleHooksMixin<T> {
  bool _installed = false;

  /// Monotonic counter that increments whenever the repo publishes new data.
  /// It scopes cached entries to the data snapshot they were computed from.
  int _dataVersion = 0;

  /// In-memory cache for query results.
  final cache = MemoryCache();

  /// Default duration for which cached query results are valid.
  Duration get cacheExpiry => const Duration(minutes: 5);

  /// Whether to invalidate the cache when new data is set.
  bool get invalidateCacheOnNewData => true;

  /// Whether to invalidate the cache when an error occurs.
  bool get invalidateCacheOnError => true;

  /// Whether to invalidate the cache when loading starts.
  bool get invalidateCacheOnLoading => true;

  /// Whether to cache `null` results from queries (negative caching).
  bool get cacheNullResults => true;

  /// Call **once** in your repo constructor to install lifecycle hooks that:
  /// - bump [_dataVersion] on new data,
  /// - (optionally) clear the cache on data/loading/error,
  /// - clear everything on dispose.
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

  /// Executes a query named [name] against the current repo data.
  ///
  /// - Returns `null` if the repo currently has no data.
  /// - Wraps execution in a telemetry span named [name].
  /// - If [cacheKey] is provided, the result is cached using a **versioned**
  ///   key that incorporates the current [_dataVersion]. Subsequent calls with
  ///   the same [name] + [cacheKey] reuse the cached result until it expires.
  /// - Pass [ttl] to override the default [cacheExpiry] for this call.
  ///
  /// IMPORTANT:
  /// - Choose a unique [name] per logical query for clean telemetry.
  /// - Provide a **stable** [cacheKey] that uniquely represents the inputs.
  Future<QueryResult?> query<QueryResult>(
    String name,
    FutureOr<QueryResult> Function(T data) query, {
    Object? cacheKey,
    Duration? ttl,
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

    log('Executing query: $name');

    if (!state.hasData) {
      log('$name: Aborting query - no data available');
      return null;
    }

    final key = _buildCacheKey(name, cacheKey);

    // Cache fast path (only when key provided)
    if (key != null && cache.contains(key)) {
      final cachedResult = cache.read<QueryResult>(key);
      if (cachedResult != null || cacheNullResults) {
        log('$name: Returning cached result ($key)');
        return cachedResult;
      }
    }

    final telemetry = get<TelemetryService>();

    QueryResult? result;
    try {
      result = await telemetry.runSpan(name, () => query(state.requireData));
    } catch (e, st) {
      log('$name: Error during query execution', e, st);
      result = null;
    }

    // Cache write (only when key provided)
    _cacheResult<QueryResult>(key, result, ttl);

    return result;
  }

  @pragma('vm:prefer-inline')
  void _cacheResult<R>(String? key, R? result, Duration? ttl) {
    if (key == null) return;
    if (result != null || cacheNullResults) {
      cache.create(key, result, expiry: ttl ?? cacheExpiry);
      log('Cached result for key: $key (ttl=${ttl ?? cacheExpiry})');
    }
  }

  @pragma('vm:prefer-inline')
  String? _buildCacheKey(String name, Object? key) {
    if (key == null) return null;

    // Stable, compact, versioned key:
    // We combine name, current data version, and a hash of the provided key.
    // Using Object.hash avoids huge strings and accidental PII in logs.
    final h = Object.hash(name, _dataVersion, key);
    return '$name|v=$_dataVersion|h=$h';
  }
}

/// A mixin that provides a method to query an item by its ID from a repository
/// containing a list of items [T].
mixin QueryByIdMixin<T, ID> on Repo<List<T>>, QueryMixin<List<T>> {
  /// Returns the matching item with the given [id], or `null` if not found.
  Future<T?> getById(ID id) async {
    return query<T?>('queryById', (data) {
      try {
        return data.firstWhere((item) => getId(item) == id);
      } catch (_) {
        log('Item with ID $id not found.');
        return null;
      }
    }, cacheKey: id);
  }

  /// Returns the ID of the given [item].
  ID getId(T item);
}

/// A mixin that provides fuzzy search capabilities for a repository
/// containing a list of items [T].
///
/// Uses the `fuzzy_bolt` package for performing fuzzy searches.
mixin FuzzyFindQueryMixin<T> on Repo<List<T>>, QueryMixin<List<T>> {
  /// Performs a fuzzy search over [fuzzySelectors] for items matching [query].
  Future<List<T>> fuzzyFind(String query) async {
    final result = await this.query<List<T>>(
      'fuzzyFind',
      (data) async {
        final r = await FuzzyBolt.searchWithConfig<T>(
          data,
          query,
          fuzzySelectors,
          fuzzySearchConfig,
        );

        return r.map(extractResult).toList();
      },
      cacheKey: query.toLowerCase(),
      ttl: const Duration(minutes: 2),
    );

    return result ?? <T>[];
  }

  /// Extracts the item of type [T] from a [FuzzyResult].
  ///
  /// Override this if your result mapping differs.
  T extractResult(FuzzyResult<T> fuzzyResult) => fuzzyResult.item;

  /// Selector functions used by the fuzzy search,
  /// e.g., `(t) => t.title`, `(t) => t.description`.
  List<String Function(T item)> get fuzzySelectors;

  /// Configuration for fuzzy search behavior.
  FuzzySearchConfig get fuzzySearchConfig => const FuzzySearchConfig();
}
