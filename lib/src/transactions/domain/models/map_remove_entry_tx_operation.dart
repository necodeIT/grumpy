import 'package:grumpy/grumpy.dart';

/// {@template map_remove_entry_tx_operation}
/// A [TxOperation] that removes an entry from a [Map].
/// {@endtemplate}
///
/// {@category transactions}

class MapRemoveEntryTxOperation<Key, Value, TResult>
    extends TxOperation<Map<Key, Value>, TResult> {
  /// {@macro map_remove_entry_tx_operation}
  MapRemoveEntryTxOperation({
    required super.name,
    required super.id,
    required super.baseVersion,
    required this.key,
    required this.removeEntry,
    required this.apply,
    super.shouldRollbackOnError = TxOperation.alwaysRollback,
  }) : super(touchedKeys: {key.toString()});

  /// The key of the entry to remove.
  final Key key;

  /// Removes the entry and returns the commit result.
  final Future<TResult> Function() removeEntry;

  /// Applies commit result to the optimistic entry and returns the confirmed map.
  final MapEntry<Key, Value> Function(Key key, TResult confirmedEntry) apply;

  @override
  Map<Key, Value>? applyConfirmed(Map<Key, Value> confirmed, TResult result) {
    final copy = Map<Key, Value>.from(confirmed);
    final optimisticEntry = apply(key, result);
    copy.remove(optimisticEntry.key);
    return copy;
  }

  @override
  Future<TResult> commit(_) => removeEntry();

  @override
  Map<Key, Value> optimisticApply(Map<Key, Value> current) {
    final copy = Map<Key, Value>.from(current);
    copy.removeWhere((k, v) => k == key);
    return copy;
  }

  @override
  String get logTag => 'MapRemoveEntryTxOperation';
}
