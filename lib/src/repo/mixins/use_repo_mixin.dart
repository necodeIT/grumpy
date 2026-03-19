import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:grumpy_annotations/grumpy_annotations.dart';
import 'package:meta/meta.dart';
import 'package:grumpy/grumpy.dart';

/// Provides use hooks for watching and accessing data within [UseRepoMixin.onDependenciesReady].
class UseHooks {
  /// Provides use hooks for watching and accessing data within [UseRepoMixin.onDependenciesReady].
  const UseHooks({required this.repo, required this.externalStream});

  /// {@template UseHooks.repo}
  /// A function that allows you to watch a [Repo] of type [R] managing data of type [S] and
  /// returns a tuple containing the data from the repo and the repo itself.
  ///
  /// {@endtemplate}
  final Future<(S, R)> Function<S, R extends Repo<S>>() repo;

  /// {@template UseHooks.externalStream}
  /// A function that watches an external change signal while reading the current
  /// value synchronously via [syncSnapshot].
  ///
  /// The [changeSignal] is treated as invalidation-only. Emitted values are
  /// ignored and only used to trigger recomputation.
  /// {@endtemplate}
  final T Function<T>(
    Object key, {
    required Stream changeSignal,
    required T Function() syncSnapshot,
  })
  externalStream;
}

final class _WatchedExternalDependency {
  _WatchedExternalDependency({
    required this.changeSignal,
    required this.subscription,
  });

  Stream changeSignal;
  StreamSubscription subscription;
  Object? lastError;
  StackTrace? lastStackTrace;

  bool get hasError => lastError != null;

  void clearError() {
    lastError = null;
    lastStackTrace = null;
  }

  void setError(Object error, StackTrace stackTrace) {
    lastError = error;
    lastStackTrace = stackTrace;
  }
}

/// A mixin that provides functionality to watch and use multiple [Repo] instances.
///
/// {@category repo}
mixin UseRepoMixin<D, E, L> on LifecycleMixin, LifecycleHooksMixin {
  final _subs = <StreamSubscription>[];
  final _watchedRepos = <Type, Repo>{};
  final _pendingRepoResolutions = <Type, Future<Repo<dynamic>>>{};
  final _watchedExternalDependencies = <Object, _WatchedExternalDependency>{};

  bool _installed = false;
  int _stateChangeVersion = 0;

  D? _lastData;
  E? _lastError;
  L? _lastLoading;

  Future<void> _onWatchedRepoStateChange(Repo changedRepo) async {
    log(
      'Detected state change in dependencies (${changedRepo.runtimeType}). Re-evaluating...',
    );
    final version = ++_stateChangeVersion;
    await _rebuildDependencyState(version);
  }

  Future<void> _rebuildDependencyState(int version) async {
    var anyLoading = false;
    Object? firstError;
    StackTrace? firstErrorStackTrace;

    D? nextData = _lastData;
    E? nextError = _lastError;
    L? nextLoading = _lastLoading;

    for (final repo in _watchedRepos.values) {
      if (repo.state.hasError) {
        log(
          'Dependency of type ${repo.runtimeType} has error. Rebuilding error state...',
        );
        final repoError = repo.state.asError;
        firstError = repoError.error;
        firstErrorStackTrace = repoError.stackTrace;
        break;
      }
      if (repo.state.isLoading) {
        log(
          'Dependency of type ${repo.runtimeType} is loading. Rebuilding loading state...',
        );
        anyLoading = true;
      }
    }

    if (firstError == null) {
      for (final entry in _watchedExternalDependencies.entries) {
        final dependency = entry.value;
        if (!dependency.hasError) continue;

        log(
          'External dependency with key ${entry.key.runtimeType} has error. Rebuilding error state...',
        );
        firstError = dependency.lastError;
        firstErrorStackTrace = dependency.lastStackTrace;
        break;
      }
    }

    final allDataReady = !anyLoading && firstError == null;

    try {
      if (firstError != null) {
        nextError = await onDependencyError(firstError, firstErrorStackTrace);
        nextLoading = null;
        nextData = null;
      } else if (anyLoading) {
        nextError = null;
        nextLoading = onDependenciesLoading();
        nextData = null;
      } else if (allDataReady) {
        log('All dependencies are ready. Rebuilding data...');
        nextError = null;
        nextLoading = null;
        nextData = await _onDependenciesReady();
        log('Dependencies ready, obtained new data.');
      }
    } on NoRepoDataError catch (e, st) {
      if (e.state.isLoading) {
        nextError = null;
        nextLoading = onDependenciesLoading();
        nextData = null;
      } else {
        nextError = await onDependencyError(e, st);
        nextLoading = null;
        nextData = null;
      }
    } catch (e, st) {
      nextError = await onDependencyError(e, st);
      nextLoading = null;
      nextData = null;
    }

    if (version != _stateChangeVersion) return;

    _lastData = nextData;
    _lastError = nextError;
    _lastLoading = nextLoading;

    log('State rebuilt, notifying listeners...');
    await dependenciesChanged();
  }

  Future<void> _discover() async {
    log('Discovering dependencies...');
    try {
      final result = await _onDependenciesReady();

      // if we already get data in the discovery phase, store it.
      _lastData = result;
      _lastError = null;
      _lastLoading = null;
    } on NoRepoDataError catch (_) {
      log('At least one dependency is not ready, waiting for updates...');
    } catch (e, st) {
      log('Error during dependency discovery: $e');
      _lastError = await onDependencyError(e, st);
      // Ignore errors during the initial discovery phase.
      // we are just trying to discover repos here.
    } finally {
      log(
        'Dependency discovery complete. Currently watching ${_watchedRepos.length} repos.',
      );
      await dependenciesChanged();
    }
  }

  /// Installs the necessary lifecycle hooks for the [UseRepoMixin].
  /// Should be called in the constructor of the class using this mixin.
  @mustCallInConstructor
  void installUseRepoHooks() {
    if (_installed) return;
    _installed = true;

    /// Set to loading state initially.
    _lastLoading = onDependenciesLoading();

    onInitialize(_discover);

    onActivate(() {
      for (final sub in _subs) {
        sub.resume();
      }
    });

    onDeactivate(() {
      for (final sub in _subs) {
        sub.pause();
      }
    });

    onDisposed(() async {
      for (final sub in _subs) {
        await sub.cancel();
      }
      _subs.clear();
    });
    onDisposed(_watchedRepos.clear);
    onDisposed(_watchedExternalDependencies.clear);
  }

  /// Watches a [Repo] of type [R] managing data of type [S] and
  /// returns a tuple containing the data from the repo and the repo itself.
  ///
  /// Throws a [NoRepoDataError] if the repo's state does not contain data.
  @Deprecated('Use the provided use arg in onDependenciesReady instead')
  @visibleForTesting
  Future<(S, R)> useRepo<S, R extends Repo<S>>() => _useRepo<S, R>();

  /// Watches an external [changeSignal] while reading the latest value
  /// synchronously from [syncSnapshot].
  ///
  /// The [changeSignal] is treated as invalidation-only. Emitted values are
  /// ignored. Use [key] as the stable identity for this dependency across
  /// rebuilds.
  @Deprecated('Use the provided use arg in onDependenciesReady instead')
  @visibleForTesting
  T watchExternal<T>(
    Object key, {
    required Stream changeSignal,
    required T Function() syncSnapshot,
  }) => _watchExternal(
    key,
    changeSignal: changeSignal,
    syncSnapshot: syncSnapshot,
  );

  Future<(S, R)> _useRepo<S, R extends Repo<S>>() async {
    if (!_installed) {
      throw StateError(
        'UseRepoMixin not installed. Call installUseRepoHooks in the constructor.',
      );
    }

    if (_watchedRepos.containsKey(R)) {
      final repo = _watchedRepos[R] as R;
      return (repo.state.requireData, repo);
    }

    final pending = _pendingRepoResolutions[R];
    if (pending != null) {
      final repo = await pending as R;
      return (repo.state.requireData, repo);
    }

    final resolveAndWatch = (() async {
      final repo = await GetIt.I.getAsync<R>();
      if (_watchedRepos.containsKey(R)) {
        return _watchedRepos[R] as R;
      }

      log('Discovered new dependency. Now watching ${repo.logTag}');
      _watchedRepos[R] = repo;

      var ignoredInitialReplay = false;
      final sub = repo.stream.listen((_) async {
        if (!ignoredInitialReplay) {
          ignoredInitialReplay = true;
          return;
        }
        await _onWatchedRepoStateChange(repo);
      });

      _subs.add(sub);
      return repo;
    })();

    _pendingRepoResolutions[R] = resolveAndWatch;
    late final R repo;
    try {
      repo = await resolveAndWatch;
    } finally {
      await _pendingRepoResolutions.remove(R);
    }

    return (repo.state.requireData, repo);
  }

  T _watchExternal<T>(
    Object key, {
    required Stream changeSignal,
    required T Function() syncSnapshot,
  }) {
    if (!_installed) {
      throw StateError(
        'UseRepoMixin not installed. Call installUseRepoHooks in the constructor.',
      );
    }

    final watchedDependency = _watchedExternalDependencies[key];
    if (watchedDependency == null) {
      _watchedExternalDependencies[key] = _subscribeToExternalDependency(
        key,
        changeSignal,
      );
    } else if (!identical(watchedDependency.changeSignal, changeSignal)) {
      _replaceExternalDependency(
        key,
        watchedDependency: watchedDependency,
        changeSignal: changeSignal,
      );
    }

    return syncSnapshot();
  }

  _WatchedExternalDependency _subscribeToExternalDependency(
    Object key,
    Stream changeSignal,
  ) {
    late final _WatchedExternalDependency watchedDependency;
    final sub = changeSignal.listen(
      (_) async {
        if (!identical(_watchedExternalDependencies[key], watchedDependency)) {
          return;
        }
        watchedDependency.clearError();
        final version = ++_stateChangeVersion;
        await _rebuildDependencyState(version);
      },
      onError: (Object error, StackTrace stackTrace) async {
        if (!identical(_watchedExternalDependencies[key], watchedDependency)) {
          return;
        }
        watchedDependency.setError(error, stackTrace);
        final version = ++_stateChangeVersion;
        await _rebuildDependencyState(version);
      },
    );

    watchedDependency = _WatchedExternalDependency(
      changeSignal: changeSignal,
      subscription: sub,
    );
    _subs.add(sub);

    return watchedDependency;
  }

  void _replaceExternalDependency(
    Object key, {
    required _WatchedExternalDependency watchedDependency,
    required Stream changeSignal,
  }) {
    _subs.remove(watchedDependency.subscription);
    unawaited(watchedDependency.subscription.cancel());
    _watchedExternalDependencies[key] = _subscribeToExternalDependency(
      key,
      changeSignal,
    );
  }

  FutureOr<D> _onDependenciesReady() => onDependenciesReady(
    UseHooks(repo: _useRepo, externalStream: _watchExternal),
  );

  /// A callback function that is called when all watched repositories are ready.
  /// Call [use.useRepo] within this function to access repositories required to build the value.
  ///
  /// [_onDependenciesReady] is called whenever any of the watched repositories emit a new state and *all* watched
  /// repositories have a state of [RepoDataState].
  ///
  /// If this function throws an exception, the error will be handled by [onDependencyError].
  FutureOr<D> onDependenciesReady(UseHooks use);

  /// A callback function that is called when any of the watched repositories emit an error state
  /// or when an exception is thrown during the execution of [_onDependenciesReady].
  ///
  /// Takes precedence over [onDependenciesLoading].
  FutureOr<E> onDependencyError(Object error, StackTrace? stackTrace);

  /// A callback function that is called when any of the watched repositories emit a loading state.
  L onDependenciesLoading();

  /// A pattern matching function that executes the appropriate callback
  /// based on the last known state of the watched repositories.
  R when<R>({
    required R Function(D data) data,
    required R Function(E error) error,
    required R Function(L loading) loading,
  }) {
    if (_lastError != null) {
      return error(_lastError as E);
    } else if (_lastLoading != null) {
      return loading(_lastLoading as L);
    } else if (_lastData != null) {
      return data(_lastData as D);
    } else {
      throw StateError('No state available to handle.');
    }
  }

  /// An asynchronous pattern matching function that executes the appropriate callback
  /// based on the last known state of the watched repositories.
  Future<R> whenAsync<R>({
    required FutureOr<R> Function(D data) data,
    required FutureOr<R> Function(E error) error,
    required FutureOr<R> Function(L loading) loading,
  }) async {
    if (_lastError != null) {
      return await error(_lastError as E);
    } else if (_lastLoading != null) {
      return await loading(_lastLoading as L);
    } else if (_lastData != null) {
      return await data(_lastData as D);
    } else {
      throw StateError('No state available to handle.');
    }
  }
}

/// A mixin that provides a deferred repository implementation using [UseRepoMixin].
///
/// The [DeferredRepoMixin] allows you to create a repository that builds its state
/// based on the states of other repositories it depends on. It leverages the
/// [UseRepoMixin] to watch and react to changes in the dependent repositories.
///
/// Dependent repositories are lazyly discovered during the initialization phase.
///
/// {@category repo}

mixin DeferredRepoMixin<T> on Repo<T>, UseRepoMixin<void, void, void> {
  @mustCallSuper
  @override
  FutureOr<void> onDependencyError(Object error, StackTrace? stackTrace) {
    this.error(error, stackTrace);
  }

  @mustCallSuper
  @override
  FutureOr<void> onDependenciesLoading() {
    loading();
  }

  @mustCallSuper
  @override
  FutureOr<void> onDependenciesReady(UseHooks use) async {
    final data = await build(use);

    this.data(data);
  }

  /// A builder function that constructs the state of this repo of type [T].
  ///
  /// When implementing this method, you can call [UseHooks.repo] to access other repositories
  /// that this repository depends on.
  FutureOr<T> build(UseHooks use);
}
