import 'dart:async';

import 'package:grumpy/grumpy.dart';
import 'package:grumpy_annotations/grumpy_annotations.dart';

/// A mixin that provides mutation capabilities to a [Repo].

@Deprecated(
  'Use TransactionalMutationMixin instead for a more robust transaction-based mutation system.',
)
mixin MutationMixins<T> on Repo<T>, RepoLifecycleHooksMixin<T>, TelemetryMixin {
  bool _installed = false;
  int _stateVersion = 0;
  int _enqueueOrder = 0;
  int _latestMutationOrder = -1;

  /// Installs required lifecycle hooks required for [MutationMixins] to function.
  @mustCallInConstructor
  void installMutationHooks() {
    if (_installed) return;

    onData((_) => _stateVersion++);
    onError((_, _) => _stateVersion++);

    _installed = true;
  }

  /// Runs a stateful mutation on the repo's current data with telemetry + analytics.
  Future<T?> mutate(
    String name,
    FutureOr<T> Function(T currentData) mutation, {
    Map<String, String>? attributes,
    String? eventName,
    RetryPolicy retryPolicy = RetryPolicy.noRetry,
    OptimisticPolicy<RepoState<T>>? optimisticPolicy,
  }) async {
    eventName ??= 'mutation_$name';

    final snapshot = state;

    if (!_installed) {
      throw StateError(
        'Mutation hooks are not installed. Please call installMutationHooks() in the constructor.',
      );
    }

    if (!state.hasData) {
      log('Cannot perform mutation $name: Repo has no data');
      return null;
    }

    _applyOptimistics(optimisticPolicy);

    final stateVersion = _stateVersion;
    final order = _enqueueOrder++;
    _latestMutationOrder = order;

    final analytics = AnalyticsService();

    try {
      log('Starting mutation $name');
      await analytics.trackEvent(eventName, properties: attributes);

      final result = await trace(name, () async {
        return await _runWithRetries<T>(
          () => mutation(snapshot.requireData),
          retryPolicy,
          name,
        );
      });

      // newer-wins for overlapping (legacy mutations are treated as overlapping)
      if (order == _latestMutationOrder) {
        data(result);
      }
      log('Completed mutation $name');
      return result;
    } catch (e, st) {
      log('Error during mutation $name', e, st);
      _revertOptimistic(optimisticPolicy, snapshot, e, stateVersion, order);

      return null;
    }
  }

  /// Runs a side-effecting action with telemetry + analytics, without repo data.
  Future<void> action(
    String name,
    FutureOr<void> Function() action, {
    Map<String, String>? attributes,
    String? eventName,
    RetryPolicy retryPolicy = RetryPolicy.noRetry,
    OptimisticPolicy<RepoState<T>>? optimisticPolicy,
  }) async {
    eventName ??= 'action_$name';

    if (!_installed) {
      throw StateError(
        'Mutation hooks are not installed. Please call installMutationHooks() in the constructor.',
      );
    }
    final snapshot = state;
    _applyOptimistics(optimisticPolicy);
    final stateVersion = _stateVersion;
    final analytics = AnalyticsService();

    try {
      log('Starting action $name');
      await analytics.trackEvent(eventName, properties: attributes);
      await trace(name, () async {
        await _runWithRetries(action, retryPolicy, name);
      });
      log('Completed action $name');
    } catch (e, st) {
      log('Error during action $name', e, st);
      _revertOptimistic(
        optimisticPolicy,
        snapshot,
        e,
        stateVersion,
        _latestMutationOrder,
      );
    }
  }

  Future<Ret> _runWithRetries<Ret>(
    FutureOr<Ret> Function() operation,
    RetryPolicy retryPolicy,
    String spanName,
  ) async {
    for (var i = 0; i < retryPolicy.maxAttempts; i++) {
      try {
        return await trace('try_$i', () async => operation());
      } catch (e) {
        if (i == retryPolicy.maxAttempts - 1) {
          log(
            'Operation in span $spanName failed on final attempt ${i + 1}/${retryPolicy.maxAttempts}',
            e,
          );
          rethrow;
        } else {
          log(
            'Operation in span $spanName failed on attempt ${i + 1}/${retryPolicy.maxAttempts}, retrying after ${retryPolicy.delay}',
            e,
          );
          await Future.delayed(retryPolicy.delay);
          continue;
        }
      }
    }

    throw StateError('Unreachable code in action retry logic');
  }

  void _applyOptimistics(OptimisticPolicy<RepoState<T>>? policy) {
    if (policy == null) return;

    final optimisticValue = policy.optimisticValue(state);

    optimisticValue.when(
      data: (d) => data(d.requireData),
      loading: (_) => loading,
      error: error,
    );
  }

  void _revertOptimistic(
    OptimisticPolicy<RepoState<T>>? policy,
    RepoState<T> snapshot,
    Object? error,
    int version,
    int order,
  ) {
    if (policy == null) return;
    if (!policy.shouldRevert(error)) return;
    if (version != _stateVersion) return;
    if (order != _latestMutationOrder) return;

    snapshot.when(
      data: (d) => data(d.requireData),
      loading: (_) => loading,
      error: this.error,
    );
  }
}
