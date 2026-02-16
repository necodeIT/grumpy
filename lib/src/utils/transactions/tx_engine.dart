import 'package:grumpy/grumpy.dart';

/// Per-repo transaction state machine with optimistic replay.
///
/// The engine tracks:
/// - confirmed state (`confirmed`)
/// - confirmed version (`confirmedVersion`)
/// - pending optimistic operations (`pending`)
///
/// Visibility model:
/// - UI-visible state is computed from `confirmed + projected pending`.
/// - overlapping pending operations are resolved via newer-wins policy.
/// - on settle, pending list is updated and visible state can be recomputed.
class TxEngine<TState> {
  /// Creates a transaction engine with initial confirmed state.
  TxEngine(TState initial) : _confirmed = initial;

  TState _confirmed;
  int _confirmedVersion = 0;
  int _nextOrder = 0;

  final List<TxPending<TState>> _pending = <TxPending<TState>>[];
  final Map<String, int> _latestSettledOrderByKey = <String, int>{};

  /// Current confirmed state.
  TState get confirmed => _confirmed;

  /// Monotonic confirmed version.
  int get confirmedVersion => _confirmedVersion;

  /// Read-only pending operations queue.
  List<TxPending<TState>> get pending => List.unmodifiable(_pending);

  /// Computes current visible state by replaying projected pending ops.
  ///
  /// This should be used after enqueue/settle to produce render state.
  TState computeVisible() {
    final projected = resolveNewerWins<TState>(_pending);
    var value = _confirmed;
    for (final op in projected) {
      value = op.apply(value);
    }
    return value;
  }

  /// Enqueues a new optimistic operation.
  ///
  /// The returned [TxPending] can be used for debugging or tracing.
  TxPending<TState> enqueue({
    required String id,
    required Set<String> touchedKeys,
    required TState Function(TState current) apply,
  }) {
    final pending = TxPending<TState>(
      id: id,
      enqueueOrder: _nextOrder++,
      touchedKeys: touchedKeys,
      apply: apply,
    );
    _pending.add(pending);
    return pending;
  }

  /// Settles operation [id] as success and optionally updates confirmed state.
  ///
  /// Settlement rules:
  /// - if the operation cannot be found, it is ignored.
  /// - if the operation is overshadowed by a newer settled op touching at least
  ///   one same key, confirmed state is not overwritten.
  /// - if [applyConfirmed] returns non-null, confirmed state updates and version
  ///   increments by one.
  void settleSuccess<TResult>(
    String id,
    TResult result,
    TState? Function(TState confirmed, TResult result) applyConfirmed,
  ) {
    final index = _pending.indexWhere((p) => p.id == id);
    if (index < 0) return;
    final settled = _pending.removeAt(index);

    final overshadowed = settled.touchedKeys.any(
      (key) => (_latestSettledOrderByKey[key] ?? -1) > settled.enqueueOrder,
    );

    if (overshadowed) {
      return;
    }

    final next = applyConfirmed(_confirmed, result);
    if (next != null) {
      _confirmed = next;
      _confirmedVersion++;
    }

    for (final key in settled.touchedKeys) {
      final current = _latestSettledOrderByKey[key] ?? -1;
      if (settled.enqueueOrder > current) {
        _latestSettledOrderByKey[key] = settled.enqueueOrder;
      }
    }
  }

  /// Settles operation [id] as failure by removing it from pending queue.
  ///
  /// Caller is expected to recompute visible state after this operation.
  void settleFailure(String id) {
    _pending.removeWhere((p) => p.id == id);
  }
}
