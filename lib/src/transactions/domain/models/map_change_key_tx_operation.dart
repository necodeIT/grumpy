import 'package:grumpy/grumpy.dart';

/// {@template map_change_key_tx_operation}
/// A [TxOperation] for changing the key of an entry in a map.
///
/// To update the value of an entry without changing the key, use [MapUpdateEntryTxOperation] instead.
/// {@endtemplate}
class MapChangeKeyTxOperation<Key, Value, TResult>
    extends TxOperation<Map<Key, Value>, TResult> {
  /// {@macro map_change_key_tx_operation}
  MapChangeKeyTxOperation({
    required super.name,
    required super.id,
    required super.baseVersion,
    required this.oldKey,
    required this.newKey,
    required this.changeKey,
    required this.apply,
    required this.conflictResolution,
    super.shouldRollbackOnError = TxOperation.alwaysRollback,
  }) : super(touchedKeys: {oldKey.toString(), newKey.toString()});

  /// The conflict resolution strategy to use when the [newKey] already exists in the confirmed state.
  final MapChangeKeyConflictResolution conflictResolution;

  /// The old key of the entry to be updated.
  final Key oldKey;

  /// The new key of the entry to be updated.
  final Key newKey;

  /// Changes the key of the entry on the remote and returns the commit result.
  final Future<TResult> Function(Key oldKey, Key newKey, Value value) changeKey;

  /// Applies commit result to the optimistic entry and returns the confirmed entry.
  final Key Function(
    Key oldKey,
    Key newKey,
    Value value,
    TResult confirmedEntry,
  )
  apply;

  @override
  Map<Key, Value>? applyConfirmed(Map<Key, Value> confirmed, TResult result) {
    if (!confirmed.containsKey(oldKey)) {
      // Old key not found, cannot apply key change
      return null;
    }

    if (confirmed.containsKey(newKey)) {
      // New key already exists, resolve conflict based on the specified strategy
      switch (conflictResolution) {
        case MapChangeKeyConflictResolution.rollback:
          // Rollback the operation by returning null
          return null;
        case MapChangeKeyConflictResolution.overwrite:
          // Overwrite the existing entry with the new key
          break;
      }
    }

    final value = confirmed[oldKey] as Value;
    final appliedNewKey = apply(oldKey, newKey, value, result);
    final copy = Map<Key, Value>.from(confirmed);
    copy.remove(oldKey);
    copy[appliedNewKey] = value;
    return copy;
  }

  @override
  Future<TResult> commit(Map<Key, Value> current) {
    if (!current.containsKey(oldKey)) {
      // Old key not found, cannot commit key change
      throw StateError('Old key not found: $oldKey');
    }
    final value = current[oldKey] as Value;
    return changeKey(oldKey, newKey, value);
  }

  @override
  Map<Key, Value> optimisticApply(Map<Key, Value> current) {
    if (!current.containsKey(oldKey)) {
      // Old key not found, cannot apply key change
      return current;
    }
    final value = current[oldKey] as Value;
    final copy = Map<Key, Value>.from(current);
    copy.remove(oldKey);
    copy[newKey] = value;
    return copy;
  }

  @override
  String get logTag => 'MapChangeKeyTxOperation';
}

/// Conflict resolution strategies for [MapChangeKeyTxOperation].
enum MapChangeKeyConflictResolution {
  /// The operation will be rolled back if the new key already exists in the confirmed state.
  rollback,

  /// The operation will overwrite the existing entry with the new key if it already exists in the confirmed state.
  overwrite,
}
