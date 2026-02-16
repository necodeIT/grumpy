import 'package:grumpy/grumpy.dart';

/// Key for persisted repo snapshots.
class RepoSnapshotKey extends Model implements StorageKey {
  /// Creates a repo snapshot key.
  const RepoSnapshotKey({
    required this.namespace,
    required this.primaryKey,
    required this.schemaId,
    this.compatVersion,
    this.userScope,
  });

  @override
  final String namespace;

  @override
  final String primaryKey;

  @override
  final String schemaId;

  @override
  final int? compatVersion;

  /// Optional user/tenant scope appended to the storage key.
  final String? userScope;

  @override
  String asStorageKey() {
    final compatPart = compatVersion == null ? '' : '|c=$compatVersion';
    final userPart = userScope == null ? '' : '|u=$userScope';
    return '$namespace|$schemaId$compatPart|$primaryKey$userPart';
  }
}
