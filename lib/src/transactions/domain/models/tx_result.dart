import 'package:grumpy/grumpy.dart';

/// Public result returned by [TransactionalMutationMixin.transact].
///
/// [success] indicates whether commit eventually succeeded.
/// [visibleState] is the repo state after settlement + replay.
class TxResult<TState> implements Model {
  /// Creates a transaction result payload.
  const TxResult({
    required this.value,
    required this.visibleState,
    required this.success,
    this.error,
    this.stackTrace,
  });

  /// Commit payload when successful.
  ///
  /// This value is `null` for failure outcomes.
  final Object? value;

  /// Visible state after settlement and replay.
  final TState visibleState;

  /// Indicates whether operation settled successfully.
  final bool success;

  /// Failure object when [success] is false.
  final Object? error;

  /// Failure stack trace when [success] is false.
  final StackTrace? stackTrace;
}
