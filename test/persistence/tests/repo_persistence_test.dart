import 'dart:async';
import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:grumpy/grumpy.dart';
import 'package:grumpy/src/persistence/infra/services/file_repo_state_persistence_service.dart';
import 'package:test/test.dart';
import '../harness/repo_persistence_test_harness.dart';

void main() {
  final di = GetIt.instance;

  setUp(() async {
    await di.reset();
  });

  tearDown(() async {
    await di.reset();
  });

  test('file repo persistence save/load roundtrip', () async {
    final dir = await Directory.systemTemp.createTemp('grumpy_repo_test_');
    final service = FileRepoStatePersistenceService(baseDir: dir);
    const key = RepoSnapshotKey(
      namespace: 'repo',
      primaryKey: 'users',
      schemaId: 'v1',
    );

    await service.save<String, String>(
      key,
      RepoSnapshot<String>(data: 'hello', savedAt: DateTime.now()),
      codec: const StringCodec(),
    );

    final loaded = await service.load<String, String>(
      key,
      codec: const StringCodec(),
    );

    expect(loaded, isNotNull);
    expect(loaded!.data, 'hello');

    await dir.delete(recursive: true);
  });

  group('Issue coverage: persistence policy wiring', () {
    test(
      'saveNullData=false skips persisting null snapshots on data emission',
      () async {
        final persistence = _RecordingRepoStatePersistenceService();
        di.registerSingleton<RepoStatePersistenceService>(persistence);
        di.registerSingleton<RepoBootstrapService>(_NoopRepoBootstrapService());

        final repo = _NullablePersistentRepo();
        addTearDown(() async => repo.free());

        repo.data(null);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(persistence.saveCalls, 0);
        expect(persistence.savedSnapshot, isNull);
      },
    );
  });
}

class _RecordingRepoStatePersistenceService
    extends RepoStatePersistenceService {
  _RecordingRepoStatePersistenceService() : super.internal();

  int saveCalls = 0;
  RepoSnapshot<Object?>? savedSnapshot;

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
  }) async {
    saveCalls++;
    savedSnapshot = snapshot as RepoSnapshot<Object?>;
  }

  @override
  Future<void> delete(RepoSnapshotKey key) async {}

  @override
  Future<void> clearNamespace(String namespace) async {}

  @override
  Future<void> free() async {}

  @override
  String get logTag => '_RecordingRepoStatePersistenceService';
}

class _NoopRepoBootstrapService extends RepoBootstrapService {
  _NoopRepoBootstrapService() : super.internal();

  @override
  Future<void> bootstrap<T, Serialized extends Object>({
    required Repo<T> repo,
    required RepoSnapshotKey key,
    required SerializationCodec<T, Serialized> codec,
    required RepoPersistencePolicy<Serialized> persistencePolicy,
    required RepoBootstrapPolicy bootstrapPolicy,
    required RepoSyncLoader<T> sync,
    required FutureOr<void> Function(T value) emitData,
    required FutureOr<void> Function(Object error, StackTrace? st) emitError,
  }) async {}

  @override
  Future<void> free() async {}

  @override
  String get logTag => '_NoopRepoBootstrapService';
}

class _NullableStringCodec implements SerializationCodec<String?, String> {
  const _NullableStringCodec();

  @override
  String? decode(String payload) => payload == '__null__' ? null : payload;

  @override
  String encode(String? value) => value ?? '__null__';
}

class _NullablePersistentRepo extends Repo<String?>
    with
        RepoLifecycleMixin<String?>,
        RepoLifecycleHooksMixin<String?>,
        TelemetryMixin,
        PersistentRepoStateMixin<String?, String> {
  _NullablePersistentRepo() {
    installRepoStatePersistenceHooks();
  }

  @override
  RepoPersistencePolicy<String> get persistencePolicy =>
      const RepoPersistencePolicy<String>(
        enabled: true,
        persistOnData: true,
        persistDebounce: Duration.zero,
        saveNullData: false,
      );

  @override
  RepoSnapshotKey get snapshotKey => const RepoSnapshotKey(
    namespace: 'repo',
    primaryKey: 'nullable',
    schemaId: 'v1',
  );

  @override
  SerializationCodec<String?, String> get snapshotCodec =>
      const _NullableStringCodec();

  @override
  Future<String?> syncFromRemote() async => null;

  @override
  String get logTag => '_NullablePersistentRepo';
}
