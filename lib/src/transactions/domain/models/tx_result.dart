import 'package:grumpy/grumpy.dart';

/// Public result returned by [TransactionalMutationMixin.transact].
///
/// Describes how a transaction settled and what visible state remained after
/// replay.
///
/// Mutation callers usually need both the remote outcome and the final visible
/// repo state.
///
/// [TxResult] stores the returned value, success flag, visible state, and
/// failure details when a commit fails.
///
/// [value] is typed as `Object?` so the result can carry arbitrary commit
/// payloads.
///
/// - `TState`: the repo state type after settlement.
/// - [value], [visibleState], [success], [error], [stackTrace].
///
/// For example:
/// ```dart
/// final result = await transact(operation);
/// if (!result.success) {}
/// ```
///
/// {@category transactions}

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
