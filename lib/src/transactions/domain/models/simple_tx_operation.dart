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
class SimpleTxOperation<TState, TResult>
    implements TxOperation<TState, TResult> {
  /// Creates a callback-based transaction operation.
  const SimpleTxOperation({
    required this.name,
    required this.id,
    required this.baseVersion,
    required TState Function(TState current) optimisticApply,
    required Future<TResult> Function(TState current) commit,
    required TState? Function(TState confirmed, TResult result) applyConfirmed,
    this.shouldRollbackOnError = TxOperation.alwaysRollback,
    this.touchedKeys = const <String>{'*'},
  }) : _optimisticApply = optimisticApply,
       _commit = commit,
       _applyConfirmed = applyConfirmed;

  @override
  final String name;

  @override
  final String id;

  @override
  final int baseVersion;

  final TState Function(TState current) _optimisticApply;

  final Future<TResult> Function(TState current) _commit;

  final TState? Function(TState confirmed, TResult result) _applyConfirmed;

  /// {@template shouldRollbackOnError}
  /// Failure rollback callback.
  ///
  /// Defaults to always true.
  /// {@endtemplate}
  final bool Function(Object error, StackTrace? stackTrace)
  shouldRollbackOnError;

  @override
  final Set<String> touchedKeys;

  @override
  TState optimisticApply(TState current) => _optimisticApply(current);

  @override
  Future<TResult> commit(TState current) => _commit(current);

  @override
  TState? applyConfirmed(TState confirmed, TResult result) {
    return _applyConfirmed(confirmed, result);
  }

  @override
  bool shouldRollback(Object error, StackTrace? stackTrace) {
    return shouldRollbackOnError(error, stackTrace);
  }
}
