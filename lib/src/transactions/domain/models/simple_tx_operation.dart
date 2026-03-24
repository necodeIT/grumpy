import 'dart:async';
import 'package:grumpy/grumpy.dart';
import 'package:grumpy/src/transactions/domain/models/tx_operation.dart';

/// Callback-based implementation of [TxOperation].
///
/// Lets repo code define a transaction inline with callbacks instead of a
/// dedicated subclass.
///
/// Many mutations are small enough that a full custom [TxOperation] class would
/// add ceremony without adding clarity.
///
/// The class stores the three transaction callbacks and forwards them to the
/// [TxOperation] contract.
///
/// The default [touchedKeys] is `{'*'}`, which treats the operation as broadly
/// overlapping with other mutations unless you narrow it explicitly.
///
/// - `TState`: the repo state type.
/// - `TResult`: the commit payload type.
/// - [optimisticApply], [commit], [applyConfirmed]: the transaction callbacks.
///
/// For example:
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
///
/// {@category transactions}

class SimpleTxOperation<TState, TResult> extends TxOperation<TState, TResult> {
  /// Creates a callback-based transaction operation.
  const SimpleTxOperation({
    required super.name,
    required super.id,
    required super.baseVersion,
    required TState Function(TState current) optimisticApply,
    required Future<TResult> Function(TState current) commit,
    required TState? Function(TState confirmed, TResult result) applyConfirmed,
    super.shouldRollbackOnError = TxOperation.alwaysRollback,
    super.touchedKeys = const <String>{'*'},
  }) : _optimisticApply = optimisticApply,
       _commit = commit,
       _applyConfirmed = applyConfirmed;

  final TState Function(TState current) _optimisticApply;

  final Future<TResult> Function(TState current) _commit;

  final TState? Function(TState confirmed, TResult result) _applyConfirmed;

  @override
  TState optimisticApply(TState current) => _optimisticApply(current);

  @override
  Future<TResult> commit(TState current) => _commit(current);

  @override
  TState? applyConfirmed(TState confirmed, TResult result) {
    return _applyConfirmed(confirmed, result);
  }

  @override
  String get logTag => 'SimpleTxOperation';
}
