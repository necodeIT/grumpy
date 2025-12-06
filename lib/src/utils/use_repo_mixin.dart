import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:meta/meta.dart';
import 'package:modular_foundation/modular_foundation.dart';

/// A mixin that provides functionality to watch and use multiple [Repo] instances.
mixin UseRepoMixin<D, E, L> on LifecycleMixin, LifecycleHooksMixin {
  final _subs = <StreamSubscription>[];
  final _watchedRepos = <Type, Repo>{};

  bool _installed = false;
  bool _handlingStateChange = false;

  D? _lastData;
  E? _lastError;
  L? _lastLoading;

  Future<void> _onWatchedRepoStateChange() async {
    if (_handlingStateChange) return;
    _handlingStateChange = true;
    bool anyLoading = false;
    RepoErrorState? firstError;

    for (final repo in _watchedRepos.values) {
      if (repo.state.hasError) {
        final errorState = repo.state.asError;

        firstError = errorState;
        break;
      } else if (repo.state.isLoading) {
        anyLoading = true;
      }
    }

    final allDataReady = !anyLoading && firstError == null;

    _lastError = firstError != null
        ? await onDependencyError(firstError.error, firstError.stackTrace)
        : null;
    _lastLoading = anyLoading ? await onDependenciesLoading() : null;

    try {
      _lastData = allDataReady ? await onDependenciesReady() : null;
    } on NoRepoDataError catch (e, st) {
      if (e.state.isLoading) {
        _lastLoading = await onDependenciesLoading();
        _lastData = null;
      } else {
        _lastError = await onDependencyError(e, st);
        _lastData = null;
      }
    } catch (e, st) {
      _lastError = await onDependencyError(e, st);
      _lastData = null;
    }

    await dependenciesChanged();

    _handlingStateChange = false;
  }

  Future<void> _discover() async {
    try {
      final result = await onDependenciesReady();

      // if we already get data in the discovery phase, store it.
      _lastData = result;
      _lastError = null;
      _lastLoading = null;
    } catch (e) {
      // Ignore errors during the initial discovery phase.
      // we are just trying to discover repos here.
    }
  }

  /// Installs the necessary lifecycle hooks for the [UseRepoMixin].
  /// Should be called in the constructor of the class using this mixin.
  @mustCallInConstructor
  void installUseRepoHooks() {
    if (_installed) return;
    _installed = true;

    /// Set to loading state initially.
    onInitialize(() async {
      _lastLoading = await onDependenciesLoading();
    });

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
    });
    onDisposed(_watchedRepos.clear);
    onDisposed(_subs.clear);
  }

  /// Watches a [Repo] of type [R] managing data of type [S] and
  /// returns a tuple containing the data from the repo and the repo itself.
  ///
  /// Throws a [NoRepoDataError] if the repo's state does not contain data.
  Future<(S, R)> useRepo<S, R extends Repo<S>>() async {
    if (!_installed) {
      throw StateError(
        'UseRepoMixin not installed. Call installUseRepoHooks in the constructor.',
      );
    }

    if (_watchedRepos.containsKey(R)) {
      final repo = _watchedRepos[R] as R;
      return (repo.state.requireData, repo);
    }

    final repo = await GetIt.I.getAsync<R>();

    _watchedRepos[R] = repo;

    final sub = repo.stream.listen((_) async {
      await _onWatchedRepoStateChange();
    });

    _subs.add(sub);

    return (repo.state.requireData, repo);
  }

  /// A callback function that is called when all watched repositories are ready.
  /// Call [useRepo] within this function to access repositories required to build the value.
  ///
  /// [onDependenciesReady] is called whenever any of the watched repositories emit a new state and *all* watched
  /// repositories have a state of [RepoDataState].
  ///
  /// If this function throws an exception, the error will be handled by [onDependencyError].
  FutureOr<D> onDependenciesReady();

  /// A callback function that is called when any of the watched repositories emit an error state
  /// or when an exception is thrown during the execution of [onDependenciesReady].
  ///
  /// Takes precedence over [onDependenciesLoading].
  FutureOr<E> onDependencyError(Object error, StackTrace? stackTrace);

  /// A callback function that is called when any of the watched repositories emit a loading state.
  FutureOr<L> onDependenciesLoading();

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

/// A typedef for [UseRepoMixin.useRepo].
///
/// **Example:**
/// ```dart
/// final (user, userRepo) = await useRepo<User, UserRepo>();
/// ```
typedef UseRepo = Future<(T, R)> Function<T, R extends Repo<T>>();

/// A mixin that provides a deferred repository implementation using [UseRepoMixin].
///
/// The [DeferredRepoMixin] allows you to create a repository that builds its state
/// based on the states of other repositories it depends on. It leverages the
/// [UseRepoMixin] to watch and react to changes in the dependent repositories.
///
/// Dependent repositories are lazyly discovered during the initialization phase.
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
  FutureOr<void> onDependenciesReady() async {
    final data = await build();

    this.data(data);
  }

  /// A builder function that constructs the state of this repo of type [T].
  ///
  /// When implementing this method, you can call [useRepo] to access other repositories
  /// that this repository depends on.
  FutureOr<T> build();
}
