import 'dart:async';
import 'package:grumpy/grumpy.dart';
export '../../shared/harness/harness.dart' show StringCodec;

class InMemorySnapshotPersistence extends RepoStatePersistenceService {
  InMemorySnapshotPersistence() : super.internal();

  RepoSnapshot<Object?>? stored;
  int loadCalls = 0;
  int saveCalls = 0;
  int deleteCalls = 0;
  int clearNamespaceCalls = 0;

  @override
  Future<RepoSnapshot<T>?> load<T, Serialized extends Object>(
    RepoSnapshotKey key, {
    required SerializationCodec<T, Serialized> codec,
  }) async {
    loadCalls++;
    return stored as RepoSnapshot<T>?;
  }

  @override
  Future<void> save<T, Serialized extends Object>(
    RepoSnapshotKey key,
    RepoSnapshot<T> snapshot, {
    required SerializationCodec<T, Serialized> codec,
  }) async {
    saveCalls++;
    stored = snapshot as RepoSnapshot<Object?>;
  }

  @override
  Future<void> delete(RepoSnapshotKey key) async {
    deleteCalls++;
    stored = null;
  }

  @override
  Future<void> clearNamespace(String namespace) async {
    clearNamespaceCalls++;
    stored = null;
  }

  @override
  Future<void> free() async {}

  @override
  String get logTag => 'InMemorySnapshotPersistence';
}

class TestRepo extends Repo<String> {
  @override
  String get logTag => 'TestRepo';
}
