import 'package:grumpy/grumpy.dart';

/// {@template map_update_entry_tx_operation}
/// A [TxOperation] for updating an entry in a map.
///
/// Note: To change the key of an entry, use [MapChangeKeyTxOperation] instead.
/// {@endtemplate}
///
/// {@category transactions}

class MapUpdateEntryTxOperation<Key, Value, TResult>
    extends TxOperation<Map<Key, Value>, TResult> {
  /// {@macro map_update_entry_tx_operation}
  const MapUpdateEntryTxOperation({
    required super.name,
    required super.id,
    required super.baseVersion,
    required this.key,
    required this.touchedValueKeys,
    required this.apply,
    required this.updateEntry,
    required this.optimisticUpdate,
  }) : super(touchedKeys: const <String>{});

  @override
  Set<String> get touchedKeys => touchedValueKeys.map((k) => '$key.$k').toSet();

  /// The key of the entry to be updated.
  final Key key;

  /// The keys of the value that are touched by this operation. This is used to determine if this operation conflicts with other operations that touch the same keys.
  final Set<String> touchedValueKeys;

  /// Applies commit result to the optimistic entry and returns the confirmed map entry.
  final MapEntry<Key, Value> Function(
    MapEntry<Key, Value> optimisticEntry,
    TResult confirmedEntry,
  )
  apply;

  /// Updates the entry on the remote and returns the commit result.
  final Future<TResult> Function(MapEntry<Key, Value> entry) updateEntry;

  /// Returns the optimistically updated value based on the current entry.
  final Value Function(MapEntry<Key, Value> current) optimisticUpdate;

  @override
  Map<Key, Value>? applyConfirmed(Map<Key, Value> confirmed, TResult result) {
    if (!confirmed.containsKey(key)) {
      // Key not found, cannot apply update
      return null;
    }
    final optimisticEntry = MapEntry(key, confirmed[key] as Value);
    final appliedEntry = apply(optimisticEntry, result);
    final copy = Map<Key, Value>.from(confirmed);
    copy[appliedEntry.key] = appliedEntry.value;
    return copy;
  }

  @override
  Future<TResult> commit(Map<Key, Value> current) {
    final currentEntry = MapEntry(key, current[key] as Value);
    return updateEntry(currentEntry);
  }

  @override
  Map<Key, Value> optimisticApply(Map<Key, Value> current) {
    final currentEntry = MapEntry(key, current[key] as Value);
    final optimisticValue = optimisticUpdate(currentEntry);
    final copy = Map<Key, Value>.from(current);
    copy[key] = optimisticValue;
    return copy;
  }

  @override
  String get logTag => 'MapUpdateEntryTxOperation';
}
