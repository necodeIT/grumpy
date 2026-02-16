import 'package:grumpy/grumpy.dart';

/// No-op repo snapshot persistence.
class NoopRepoStatePersistenceService extends RepoStatePersistenceService {
  /// Creates a no-op persistence service.
  NoopRepoStatePersistenceService() : super.internal();

  @override
  Future<RepoSnapshot<T>?> load<T, Serialized extends Object>(
    RepoSnapshotKey key, {
    required SerializationCodec<T, Serialized> codec,
  }) async => null;

  @override
  Future<void> save<T, Serialized extends Object>(
    RepoSnapshotKey key,
    RepoSnapshot<T> snapshot, {
    required SerializationCodec<T, Serialized> codec,
  }) async {}

  @override
  Future<void> delete(RepoSnapshotKey key) async {}

  @override
  Future<void> clearNamespace(String namespace) async {}

  @override
  Future<void> free() async {}

  @override
  String get logTag => 'NoopRepoStatePersistenceService';
}
