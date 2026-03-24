import 'package:grumpy/grumpy.dart';

/// Internal pending operation envelope used by [TxEngine].
///
/// Represents one enqueued optimistic operation inside the transaction engine.
///
/// The engine needs a replay-friendly shape that is smaller and more focused
/// than the full [TxOperation].
///
/// [TxPending] stores the enqueue order, touched keys, and projection callback
/// used to recompute visible state.
///
/// This is an engine-facing model. Most repo code works with [TxOperation] and
/// [TxResult] instead.
///
/// - `TState`: the repo state type being projected.
/// - [id], [enqueueOrder], [touchedKeys], [apply]: replay metadata.
///
/// For example:
/// ```dart
/// final pending = engine.pending;
/// ```
///
/// {@category transactions}

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
