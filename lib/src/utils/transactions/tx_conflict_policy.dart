import 'package:grumpy/grumpy.dart';

/// Newer-wins conflict resolver for overlapping touched keys.
///
/// For each touched key, only the latest pending operation touching that key is
/// kept in optimistic projection. Operations that touch only disjoint keys are
/// preserved and can compose together.
///
/// Example:
/// - opA touches `profile.name`
/// - opB touches `profile.name`
/// - opC touches `profile.avatar`
///
/// Projection keeps: `opB + opC`, and excludes `opA`.
List<TxPending<TState>> resolveNewerWins<TState>(
  List<TxPending<TState>> pending,
) {
  final latestByKey = <String, int>{};
  for (var i = 0; i < pending.length; i++) {
    for (final key in pending[i].touchedKeys) {
      latestByKey[key] = i;
    }
  }

  final resolved = <TxPending<TState>>[];
  for (var i = 0; i < pending.length; i++) {
    final candidate = pending[i];
    final overshadowed = candidate.touchedKeys.any((k) => latestByKey[k] != i);
    if (!overshadowed) {
      resolved.add(candidate);
    }
  }

  return resolved;
}
