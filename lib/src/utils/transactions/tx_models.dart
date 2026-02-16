/// Internal pending operation envelope used by [TxEngine].
///
/// A [TxPending] stores the minimal metadata needed to replay an operation
/// deterministically in optimistic projection order.
class TxPending<TState> {
  /// Creates pending operation metadata.
  const TxPending({
    required this.id,
    required this.enqueueOrder,
    required this.touchedKeys,
    required this.apply,
  });

  /// Operation identifier.
  ///
  /// Should match the originating [TxOperation.id].
  final String id;

  /// Enqueue order used for deterministic replay.
  ///
  /// Lower value means the operation was enqueued earlier.
  final int enqueueOrder;

  /// Coarse conflict keys touched by this operation.
  final Set<String> touchedKeys;

  /// Optimistic state projection callback.
  final TState Function(TState current) apply;
}

/// Public result returned by [TransactionalMutationMixin.transact].
///
/// [success] indicates whether commit eventually succeeded.
/// [visibleState] is the repo state after settlement + replay.
class TxResult<TState> {
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
