import 'dart:async';

import 'package:grumpy_annotations/grumpy_annotations.dart';
import 'package:grumpy/grumpy.dart';

/// Transaction-based mutation adapter for repos.
///
/// This mixin provides `transact(...)` as a higher-level mutation API with:
/// - optimistic UI projection
/// - retry around commit phase
/// - deterministic replay after settle
/// - telemetry/analytics integration
///
/// Usage:
/// 1. mix this into a repo that also includes `RepoLifecycleHooksMixin`.
/// 2. call [installTransactionHooks] in the constructor.
/// 3. seed initial `RepoState.data` before first transaction.
/// 4. expose domain methods that call [transact] with a [TxOperation].
///
/// Example:
/// ```dart
/// class SettingsRepo extends Repo<SettingsState>
///     with RepoLifecycleMixin<SettingsState>,
///          RepoLifecycleHooksMixin<SettingsState>,
///          TelemetryMixin,
///          TransactionalMutationMixin<SettingsState> {
///   SettingsRepo(this._ds) {
///     installTransactionHooks();
///   }
///
///   final SettingsDatasource _ds;
///
///   Future<TxResult<SettingsState>> setTheme(String theme) {
///     return transact<SettingsState>(
///       SimpleTxOperation<SettingsState, SettingsState>(
///         name: 'setTheme',
///         id: nextTxId(),
///         baseVersion: 0,
///         touchedKeys: const {'settings.theme'},
///         optimisticApply: (s) => s.copyWith(theme: theme),
///         commit: () => _ds.setTheme(theme),
///         applyConfirmed: (confirmed, result) => result,
///       ),
///     );
///   }
/// }
/// ```
mixin TransactionalMutationMixin<T>
    on Repo<T>, RepoLifecycleHooksMixin<T>, TelemetryMixin {
  bool _installed = false;
  int _id = 0;
  TxEngine<T>? _engine;

  TxEngine<T> get _tx {
    final tx = _engine;
    if (tx == null) {
      throw StateError(
        'Transaction engine not initialized. Repo has no data yet.',
      );
    }
    return tx;
  }

  @mustCallInConstructor
  /// Installs lifecycle hooks required for transaction support.
  ///
  /// This hook wires transaction-engine initialization to first data emission.
  /// Calling this multiple times is safe.
  void installTransactionHooks() {
    if (_installed) return;

    onData((data) {
      _engine ??= TxEngine<T>(data);
    });

    _installed = true;
  }

  /// Enqueues and executes [operation] as a transaction.
  ///
  /// Behavior summary:
  /// - applies optimistic projection immediately
  /// - emits analytics event (`mutation_<name>` by default)
  /// - runs commit with retry policy
  /// - settles engine and emits replayed visible state
  ///
  /// Returns [TxResult] with final visible state and success/failure metadata.
  Future<TxResult<T>> transact<TResult>(
    TxOperation<T, TResult> operation, {
    String? analyticsEvent,
    Map<String, String>? analyticsAttributes,
    RetryPolicy retryPolicy = RetryPolicy.noRetry,
  }) async {
    if (!_installed) {
      throw StateError(
        'Transaction hooks are not installed. Please call installTransactionHooks() in the constructor.',
      );
    }

    if (!state.hasData) {
      throw StateError('Cannot transact without RepoState.data.');
    }

    final engine = _tx;

    engine.enqueue(
      id: operation.id,
      touchedKeys: operation.touchedKeys,
      apply: operation.optimisticApply,
    );

    data(engine.computeVisible());

    final event = analyticsEvent ?? 'mutation_${operation.name}';
    await AnalyticsService().trackEvent(event, properties: analyticsAttributes);

    try {
      final result = await trace(operation.name, () async {
        return await _runWithRetries<TResult>(
          operation.commit,
          retryPolicy,
          operation.name,
        );
      });

      engine.settleSuccess<TResult>(
        operation.id,
        result,
        operation.applyConfirmed,
      );
      final visible = engine.computeVisible();
      data(visible);
      return TxResult<T>(value: result, visibleState: visible, success: true);
    } catch (e, st) {
      engine.settleFailure(operation.id);
      final visible = engine.computeVisible();
      data(visible);
      return TxResult<T>(
        value: null,
        visibleState: visible,
        success: false,
        error: e,
        stackTrace: st,
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
        }

        await Future<void>.delayed(retryPolicy.delay);
      }
    }

    throw StateError('Unreachable retry state');
  }

  /// Generates a monotonically increasing transaction ID for this repo instance.
  String nextTxId() => '${runtimeType}_tx_${_id++}';
}
