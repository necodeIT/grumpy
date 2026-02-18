import 'package:grumpy/grumpy.dart';

/// Internal pending operation envelope used by [TxEngine].
///
/// A [TxPending] stores the minimal metadata needed to replay an operation
/// deterministically in optimistic projection order.
class TxPending<TState> implements Model {
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
