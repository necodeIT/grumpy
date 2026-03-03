import 'package:grumpy/grumpy.dart';

/// No-op repo snapshot persistence.
///
/// {@category persistence}

class NoopRepoStatePersistenceService extends RepoStatePersistenceService {
  /// Creates a no-op persistence service.
  NoopRepoStatePersistenceService() : super.internal();

  @override
  Future<RepoSnapshot<T>?> load<T, Serialized extends Object>(
    StorageKey key, {
    required SerializationCodec<T, Serialized> codec,
  }) async => null;

  @override
  Future<void> save<T, Serialized extends Object>(
    StorageKey key,
    RepoSnapshot<T> snapshot, {
    required SerializationCodec<T, Serialized> codec,
  }) async {}

  @override
  Future<void> delete(StorageKey key) async {}

  @override
  Future<void> clearNamespace(String namespace) async {}

  @override
  Future<void> destroy() async {}

  @override
  String get logTag => 'NoopRepoStatePersistenceService';
}
