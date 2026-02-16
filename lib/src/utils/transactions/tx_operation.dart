import 'dart:async';

/// Describes a single transaction intent for [TransactionalMutationMixin].
///
/// A transaction operation models one user action end-to-end:
/// 1. optimistic projection (`optimisticApply`)
/// 2. remote side effect (`commit`)
/// 3. confirmed reconciliation (`applyConfirmed`)
///
/// Implementations should be deterministic and side-effect free in
/// [optimisticApply] so the runtime can safely replay pending operations.
///
/// Typical mapping:
/// - `name`: telemetry/analytics label.
/// - `id`: per-enqueue unique identifier (for settlement bookkeeping).
/// - `touchedKeys`: coarse conflict scope (for newer-wins overlap handling).
/// - `commit`: the actual network/database mutation.
/// - `applyConfirmed`: how server response updates confirmed state.
abstract interface class TxOperation<TState, TResult> {
  /// Logical operation name used for telemetry/analytics.
  String get name;

  /// Unique operation identifier for this enqueue.
  ///
  /// Use [TransactionalMutationMixin.nextTxId] for a repo-scoped unique value.
  String get id;

  /// Confirmed version observed when this operation was created.
  ///
  /// This is informational in the current engine and is useful for telemetry
  /// or future policy decisions.
  int get baseVersion;

  /// Deterministic optimistic transform applied immediately to visible state.
  ///
  /// This must be pure: do not mutate shared objects or call I/O here.
  TState optimisticApply(TState current);

  /// Performs the remote side effect and returns commit payload.
  Future<TResult> commit();

  /// Reconciles commit result into confirmed state.
  ///
  /// Return `null` when commit payload does not alter confirmed state
  /// (for example, write-only endpoints).
  TState? applyConfirmed(TState confirmed, TResult result);

  /// Indicates whether failure should be treated as rollback-worthy.
  ///
  /// Current engine behavior removes failed operations from pending replay.
  /// Keep this signal for policy compatibility and future behavior switches.
  bool shouldRollback(Object error, StackTrace? stackTrace);

  /// Coarse keys describing state region modified by this operation.
  ///
  /// Overlapping keys participate in newer-wins projection. Disjoint keys can
  /// be composed together.
  Set<String> get touchedKeys;
}

/// Callback-based implementation of [TxOperation].
///
/// Useful for concise repo APIs:
///
/// ```dart
/// Future<TxResult<SettingsState>> setTheme(String theme) {
///   return transact<SettingsState>(
///     SimpleTxOperation<SettingsState, SettingsState>(
///       name: 'setTheme',
///       id: nextTxId(),
///       baseVersion: 0,
///       touchedKeys: const {'settings.theme'},
///       optimisticApply: (s) => s.copyWith(theme: theme),
///       commit: () => _ds.setTheme(theme),
///       applyConfirmed: (confirmed, result) => result,
///     ),
///   );
/// }
/// ```
class SimpleTxOperation<TState, TResult>
    implements TxOperation<TState, TResult> {
  /// Creates a callback-based transaction operation.
  const SimpleTxOperation({
    required this.name,
    required this.id,
    required this.baseVersion,
    required TState Function(TState current) optimisticApply,
    required Future<TResult> Function() commit,
    required TState? Function(TState confirmed, TResult result) applyConfirmed,
    this.shouldRollbackOnError = _alwaysRollback,
    this.touchedKeys = const <String>{'*'},
  }) : _optimisticApply = optimisticApply,
       _commit = commit,
       _applyConfirmed = applyConfirmed;

  static bool _alwaysRollback(Object _, StackTrace? _) => true;

  @override
  final String name;

  @override
  final String id;

  @override
  final int baseVersion;

  final TState Function(TState current) _optimisticApply;

  final Future<TResult> Function() _commit;

  final TState? Function(TState confirmed, TResult result) _applyConfirmed;

  /// Failure rollback callback.
  ///
  /// Defaults to always true.
  final bool Function(Object error, StackTrace? stackTrace)
  shouldRollbackOnError;

  @override
  final Set<String> touchedKeys;

  @override
  TState optimisticApply(TState current) => _optimisticApply(current);

  @override
  Future<TResult> commit() => _commit();

  @override
  TState? applyConfirmed(TState confirmed, TResult result) {
    return _applyConfirmed(confirmed, result);
  }

  @override
  bool shouldRollback(Object error, StackTrace? stackTrace) {
    return shouldRollbackOnError(error, stackTrace);
  }
}
