import 'package:grumpy/grumpy.dart';

/// {@template map_put_entry_tx_operation}
/// A [TxOperation] for putting an entry in a map.
/// {@endtemplate}
///
/// {@category transactions}

class MapPutEntryTxOperation<Key, Value, TResult>
    extends TxOperation<Map<Key, Value>, TResult> {
  /// {@macro map_put_entry_tx_operation}
  MapPutEntryTxOperation({
    required super.name,
    required super.id,
    required super.baseVersion,
    required this.key,
    required this.optimisticValue,
    super.shouldRollbackOnError = TxOperation.alwaysRollback,
    required this.putEntry,
    required this.apply,
  }) : super(touchedKeys: {key.toString()});

  /// The key of the entry to be put in the map.
  final Key key;

  /// Creates the entry on the remote and returns the commit result.
  final Future<TResult> Function() putEntry;

  /// The optimistic value to be put in the map.
  final Value optimisticValue;

  /// Applies commit result to the optimistic entry and returns the confirmed map.
  final MapEntry<Key, Value> Function(
    Key key,
    Value optimisticValue,
    TResult putResult,
  )
  apply;

  @override
  Map<Key, Value>? applyConfirmed(Map<Key, Value> confirmed, TResult result) {
    final copy = Map<Key, Value>.from(confirmed);
    final appliedEntry = apply(key, optimisticValue, result);
    copy[appliedEntry.key] = appliedEntry.value;
    return copy;
  }

  @override
  Map<Key, Value> optimisticApply(Map<Key, Value> current) {
    final copy = Map<Key, Value>.from(current);
    copy[key] = optimisticValue;
    return copy;
  }

  @override
  Future<TResult> commit(_) => putEntry();

  @override
  String get logTag => 'MapPutEntryTxOperation';
}
