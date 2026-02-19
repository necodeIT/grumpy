import 'dart:async';
import 'package:grumpy/grumpy.dart';
import 'package:grumpy/src/transactions/domain/models/tx_operation.dart';

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
