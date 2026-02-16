import 'dart:async';

import 'package:grumpy/grumpy.dart';
import 'package:grumpy/src/infra/services/default_repo_bootstrap_service.dart';
import 'package:test/test.dart';

void main() {
  group('Spec: repo_state_persistence_and_bootstrap_sync', () {
    test(
      'hydrates snapshot then syncs and persists when mode is hydrateThenSync',
      () async {
        final persistence = _InMemorySnapshotPersistence()
          ..stored = RepoSnapshot<String>(
            data: 'local',
            savedAt: DateTime.now().subtract(const Duration(minutes: 5)),
          );
        final repo = _TestRepo();
        final emittedData = <String>[];
        final emittedErrors = <Object>[];
        final service = DefaultRepoBootstrapService(
          persistenceService: persistence,
        );
        const key = RepoSnapshotKey(
          namespace: 'repo',
          primaryKey: 'users',
          schemaId: 'v1',
        );

        await service.bootstrap<String, String>(
          repo: repo,
          key: key,
          codec: const _StringCodec(),
          persistencePolicy: const RepoPersistencePolicy<String>(enabled: true),
          bootstrapPolicy: const RepoBootstrapPolicy(
            mode: BootstrapHydrationMode.hydrateThenSync,
          ),
          sync: () async => 'remote',
          emitData: (value) {
            emittedData.add(value);
            repo.data(value);
          },
          emitError: (error, st) => emittedErrors.add(error),
        );

        expect(
          emittedData,
          ['local', 'remote'],
          reason:
              'Spec: repo_state_persistence_and_bootstrap_sync §6 requires hydrate-first then sync update ordering.',
        );
        expect(
          persistence.saveCalls,
          1,
          reason:
              'Spec: repo_state_persistence_and_bootstrap_sync §8.2 requires successful sync results to be persisted.',
        );
        expect(
          emittedErrors,
          isEmpty,
          reason:
              'Spec: repo_state_persistence_and_bootstrap_sync §6 expects clean path without error emission on success.',
        );
      },
    );

    test(
      'skips sync after hydration when syncAfterHydration is disabled',
      () async {
        final persistence = _InMemorySnapshotPersistence()
          ..stored = RepoSnapshot<String>(
            data: 'local',
            savedAt: DateTime.now(),
          );
        final repo = _TestRepo();
        final emittedData = <String>[];
        var syncCalls = 0;
        final service = DefaultRepoBootstrapService(
          persistenceService: persistence,
        );

        await service.bootstrap<String, String>(
          repo: repo,
          key: const RepoSnapshotKey(
            namespace: 'repo',
            primaryKey: 'users',
            schemaId: 'v1',
          ),
          codec: const _StringCodec(),
          persistencePolicy: const RepoPersistencePolicy<String>(enabled: true),
          bootstrapPolicy: const RepoBootstrapPolicy(
            mode: BootstrapHydrationMode.hydrateThenSync,
            syncAfterHydration: false,
          ),
          sync: () async {
            syncCalls++;
            return 'remote';
          },
          emitData: emittedData.add,
          emitError: (_, _) {},
        );

        expect(
          emittedData,
          ['local'],
          reason:
              'Spec: repo_state_persistence_and_bootstrap_sync §7.2 allows bootstrap sync to be policy-disabled after hydration.',
        );
        expect(
          syncCalls,
          0,
          reason:
              'Spec: repo_state_persistence_and_bootstrap_sync §7.2 requires sync suppression when syncAfterHydration is false.',
        );
      },
    );

    test('hydrates only when mode is hydrateOnly', () async {
      final persistence = _InMemorySnapshotPersistence()
        ..stored = RepoSnapshot<String>(data: 'local', savedAt: DateTime.now());
      final service = DefaultRepoBootstrapService(
        persistenceService: persistence,
      );
      final emittedData = <String>[];
      var syncCalls = 0;

      await service.bootstrap<String, String>(
        repo: _TestRepo(),
        key: const RepoSnapshotKey(
          namespace: 'repo',
          primaryKey: 'users',
          schemaId: 'v1',
        ),
        codec: const _StringCodec(),
        persistencePolicy: const RepoPersistencePolicy<String>(enabled: true),
        bootstrapPolicy: const RepoBootstrapPolicy(
          mode: BootstrapHydrationMode.hydrateOnly,
        ),
        sync: () async {
          syncCalls++;
          return 'remote';
        },
        emitData: emittedData.add,
        emitError: (_, _) {},
      );

      expect(
        emittedData,
        ['local'],
        reason:
            'Spec: repo_state_persistence_and_bootstrap_sync §7.2 defines hydrateOnly mode as local hydration without sync.',
      );
      expect(
        syncCalls,
        0,
        reason:
            'Spec: repo_state_persistence_and_bootstrap_sync §7.2 requires no remote sync in hydrateOnly mode.',
      );
    });

    test('syncs only when mode is syncOnly', () async {
      final persistence = _InMemorySnapshotPersistence()
        ..stored = RepoSnapshot<String>(data: 'local', savedAt: DateTime.now());
      final service = DefaultRepoBootstrapService(
        persistenceService: persistence,
      );
      final emittedData = <String>[];

      await service.bootstrap<String, String>(
        repo: _TestRepo(),
        key: const RepoSnapshotKey(
          namespace: 'repo',
          primaryKey: 'users',
          schemaId: 'v1',
        ),
        codec: const _StringCodec(),
        persistencePolicy: const RepoPersistencePolicy<String>(enabled: true),
        bootstrapPolicy: const RepoBootstrapPolicy(
          mode: BootstrapHydrationMode.syncOnly,
        ),
        sync: () async => 'remote',
        emitData: emittedData.add,
        emitError: (_, _) {},
      );

      expect(
        emittedData,
        ['remote'],
        reason:
            'Spec: repo_state_persistence_and_bootstrap_sync §7.2 defines syncOnly as remote-first without hydration.',
      );
      expect(
        persistence.loadCalls,
        0,
        reason:
            'Spec: repo_state_persistence_and_bootstrap_sync §7.2 requires hydration to be skipped in syncOnly mode.',
      );
    });

    test('syncThenHydrate hydrates when sync does not provide data', () async {
      final persistence = _InMemorySnapshotPersistence()
        ..stored = RepoSnapshot<String>(data: 'local', savedAt: DateTime.now());
      final repo = _TestRepo();
      final emittedData = <String>[];
      final service = DefaultRepoBootstrapService(
        persistenceService: persistence,
      );

      await service.bootstrap<String, String>(
        repo: repo,
        key: const RepoSnapshotKey(
          namespace: 'repo',
          primaryKey: 'users',
          schemaId: 'v1',
        ),
        codec: const _StringCodec(),
        persistencePolicy: const RepoPersistencePolicy<String>(enabled: true),
        bootstrapPolicy: const RepoBootstrapPolicy(
          mode: BootstrapHydrationMode.syncThenHydrate,
        ),
        sync: () async => null,
        emitData: (value) {
          emittedData.add(value);
          repo.data(value);
        },
        emitError: (_, _) {},
      );

      expect(
        emittedData,
        ['local'],
        reason:
            'Spec: repo_state_persistence_and_bootstrap_sync §6 requires syncThenHydrate fallback when sync has no usable payload.',
      );
      expect(
        persistence.loadCalls,
        1,
        reason:
            'Spec: repo_state_persistence_and_bootstrap_sync §8.2 requires hydration attempt in syncThenHydrate fallback path.',
      );
    });

    test(
      'rejects expired hydration when allowExpiredHydration is false',
      () async {
        final persistence = _InMemorySnapshotPersistence()
          ..stored = RepoSnapshot<String>(
            data: 'expired',
            savedAt: DateTime.now().subtract(const Duration(days: 3)),
            expiresAt: DateTime.now().subtract(const Duration(days: 1)),
          );
        final service = DefaultRepoBootstrapService(
          persistenceService: persistence,
        );
        final emittedData = <String>[];

        await service.bootstrap<String, String>(
          repo: _TestRepo(),
          key: const RepoSnapshotKey(
            namespace: 'repo',
            primaryKey: 'users',
            schemaId: 'v1',
          ),
          codec: const _StringCodec(),
          persistencePolicy: const RepoPersistencePolicy<String>(enabled: true),
          bootstrapPolicy: const RepoBootstrapPolicy(
            allowExpiredHydration: false,
          ),
          sync: () async => null,
          emitData: emittedData.add,
          emitError: (_, _) {},
        );

        expect(
          emittedData,
          isEmpty,
          reason:
              'Spec: repo_state_persistence_and_bootstrap_sync §7.2 requires expired snapshot rejection when policy disallows it.',
        );
      },
    );

    test(
      'emits error on sync failure when failureBehavior is emitErrorState',
      () async {
        final persistence = _InMemorySnapshotPersistence()
          ..stored = RepoSnapshot<String>(
            data: 'local',
            savedAt: DateTime.now(),
          );
        final service = DefaultRepoBootstrapService(
          persistenceService: persistence,
        );
        final emittedErrors = <Object>[];

        await service.bootstrap<String, String>(
          repo: _TestRepo(),
          key: const RepoSnapshotKey(
            namespace: 'repo',
            primaryKey: 'users',
            schemaId: 'v1',
          ),
          codec: const _StringCodec(),
          persistencePolicy: const RepoPersistencePolicy<String>(enabled: true),
          bootstrapPolicy: const RepoBootstrapPolicy(
            failureBehavior: SyncFailureBehavior.emitErrorState,
          ),
          sync: () async => throw StateError('sync failed'),
          emitData: (_) {},
          emitError: (error, st) => emittedErrors.add(error),
        );

        expect(
          emittedErrors.length,
          1,
          reason:
              'Spec: repo_state_persistence_and_bootstrap_sync §7.2 defines explicit sync-failure behavior with error-state emission.',
        );
        expect(
          emittedErrors.single,
          isA<StateError>(),
          reason:
              'Spec: repo_state_persistence_and_bootstrap_sync §7.2 requires sync exceptions to surface when policy requests emitErrorState.',
        );
      },
    );

    test(
      'keeps hydrated data without emitting error on sync failure by default',
      () async {
        final persistence = _InMemorySnapshotPersistence()
          ..stored = RepoSnapshot<String>(
            data: 'local',
            savedAt: DateTime.now(),
          );
        final service = DefaultRepoBootstrapService(
          persistenceService: persistence,
        );
        final emittedData = <String>[];
        final emittedErrors = <Object>[];

        await service.bootstrap<String, String>(
          repo: _TestRepo(),
          key: const RepoSnapshotKey(
            namespace: 'repo',
            primaryKey: 'users',
            schemaId: 'v1',
          ),
          codec: const _StringCodec(),
          persistencePolicy: const RepoPersistencePolicy<String>(enabled: true),
          bootstrapPolicy: const RepoBootstrapPolicy(),
          sync: () async => throw StateError('sync failed'),
          emitData: emittedData.add,
          emitError: (error, st) => emittedErrors.add(error),
        );

        expect(
          emittedData,
          ['local'],
          reason:
              'Spec: repo_state_persistence_and_bootstrap_sync §1 and §6 target fast local hydration even when remote sync later fails.',
        );
        expect(
          emittedErrors,
          isEmpty,
          reason:
              'Spec: repo_state_persistence_and_bootstrap_sync §7.2 default keepHydratedData suppresses repo error emission.',
        );
      },
    );

    test('applies sync timeout and follows failure policy', () async {
      final persistence = _InMemorySnapshotPersistence();
      final service = DefaultRepoBootstrapService(
        persistenceService: persistence,
      );
      final emittedErrors = <Object>[];

      await service.bootstrap<String, String>(
        repo: _TestRepo(),
        key: const RepoSnapshotKey(
          namespace: 'repo',
          primaryKey: 'users',
          schemaId: 'v1',
        ),
        codec: const _StringCodec(),
        persistencePolicy: const RepoPersistencePolicy<String>(enabled: true),
        bootstrapPolicy: const RepoBootstrapPolicy(
          mode: BootstrapHydrationMode.syncOnly,
          syncTimeout: Duration(milliseconds: 20),
          failureBehavior: SyncFailureBehavior.emitErrorState,
        ),
        sync: () async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return 'late';
        },
        emitData: (_) {},
        emitError: (error, st) => emittedErrors.add(error),
      );

      expect(
        emittedErrors.single,
        isA<TimeoutException>(),
        reason:
            'Spec: repo_state_persistence_and_bootstrap_sync §7.2 defines timeout as part of bootstrap sync policy.',
      );
    });
  });
}

class _InMemorySnapshotPersistence extends RepoStatePersistenceService {
  _InMemorySnapshotPersistence() : super.internal();

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
  String get logTag => '_InMemorySnapshotPersistence';
}

class _TestRepo extends Repo<String> {
  @override
  String get logTag => '_TestRepo';
}

class _StringCodec implements SerializationCodec<String, String> {
  const _StringCodec();

  @override
  String decode(String payload) => payload;

  @override
  String encode(String value) => value;
}
