import 'dart:async';

import 'package:grumpy/grumpy.dart';

/// {@template tx_operation}
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
/// {@endtemplate}
abstract class TxOperation<TState, TResult> implements Model {
  /// {@macro tx_operation}
  const TxOperation({
    required this.name,
    required this.id,
    required this.baseVersion,
    required this.touchedKeys,
  });

  /// Default rollback policy that treats all errors as rollback-worthy.
  static bool alwaysRollback(Object _, StackTrace? _) => true;

  /// Logical operation name used for telemetry/analytics.
  final String name;

  /// Unique operation identifier for this enqueue.
  ///
  /// Use [TransactionalMutationMixin.nextTxId] for a repo-scoped unique value.
  final String id;

  /// Confirmed version observed when this operation was created.
  ///
  /// This is informational in the current engine and is useful for telemetry
  /// or future policy decisions.
  final int baseVersion;

  /// Deterministic optimistic transform applied immediately to visible state.
  ///
  /// This must be pure: do not mutate shared objects or call I/O here.
  TState optimisticApply(TState current);

  /// Performs the remote side effect and returns commit payload.
  Future<TResult> commit(TState current);

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
  final Set<String> touchedKeys;
}
