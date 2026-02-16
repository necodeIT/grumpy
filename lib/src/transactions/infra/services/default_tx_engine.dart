import 'package:grumpy/grumpy.dart';

/// Default concrete transaction engine implementation.
class DefaultTxEngine<TState> extends TxEngine<TState> {
  /// Creates a default transaction engine.
  DefaultTxEngine() : super.internal();

  late TState _confirmed;
  var _isOiled = false;
  int _confirmedVersion = 0;
  int _nextOrder = 0;

  final List<TxPending<TState>> _pending = <TxPending<TState>>[];
  final Map<String, int> _latestSettledOrderByKey = <String, int>{};

  TState _requireConfirmed() {
    if (!_isOiled) {
      throw StateError('TxEngine is not oiled. Call TxEngine(seed) first.');
    }
    return _confirmed;
  }

  @override
  void oil(TState seed) {
    _confirmed = seed;
    _isOiled = true;
    _confirmedVersion = 0;
    _nextOrder = 0;
    _pending.clear();
    _latestSettledOrderByKey.clear();
  }

  @override
  TState get confirmed => _requireConfirmed();

  @override
  int get confirmedVersion => _confirmedVersion;

  @override
  List<TxPending<TState>> get pending => List.unmodifiable(_pending);

  @override
  TState computeVisible() {
    final projected = resolveNewerWins<TState>(_pending);
    var value = _requireConfirmed();
    for (final op in projected) {
      value = op.apply(value);
    }
    return value;
  }

  @override
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

  @override
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

    final next = applyConfirmed(_requireConfirmed(), result);
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

  @override
  void settleFailure(String id) {
    _pending.removeWhere((p) => p.id == id);
  }

  @override
  String get group => '${super.group}.TxEngine';

  @override
  String get logTag => 'DefaultTxEngine';

  @override
  void free() {}
}
