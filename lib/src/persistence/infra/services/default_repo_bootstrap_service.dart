import 'dart:async';

import 'package:grumpy/grumpy.dart';

/// Default bootstrap orchestration for persistent repos.
///
/// This implementation encodes policy-driven startup flow:
/// - hydrate from local snapshot when enabled
/// - sync remote data based on mode
/// - persist synced data when persistence is enabled
/// - emit errors only when failure policy requires it
class DefaultRepoBootstrapService extends RepoBootstrapService {
  /// Creates a default bootstrap service.
  DefaultRepoBootstrapService({RepoStatePersistenceService? persistenceService})
    : _persistenceService = persistenceService,
      super.internal();

  final RepoStatePersistenceService? _persistenceService;

  RepoStatePersistenceService get _persistence =>
      _persistenceService ?? RepoStatePersistenceService();

  /// Executes bootstrap sequence for a single repo activation.
  @override
  Future<void> bootstrap<T, Serialized extends Object>({
    required Repo<T> repo,
    required StorageKey key,
    required SerializationCodec<T, Serialized> codec,
    required RepoPersistencePolicy<Serialized> persistencePolicy,
    required RepoBootstrapPolicy bootstrapPolicy,
    required RepoSyncLoader<T> sync,
    required FutureOr<void> Function(T value) emitData,
    required FutureOr<void> Function(Object error, StackTrace? st) emitError,
  }) async {
    final shouldHydrate =
        bootstrapPolicy.mode == BootstrapHydrationMode.hydrateThenSync ||
        bootstrapPolicy.mode == BootstrapHydrationMode.hydrateOnly ||
        bootstrapPolicy.mode == BootstrapHydrationMode.syncThenHydrate;

    final shouldSync =
        bootstrapPolicy.mode == BootstrapHydrationMode.hydrateThenSync ||
        bootstrapPolicy.mode == BootstrapHydrationMode.syncOnly ||
        bootstrapPolicy.mode == BootstrapHydrationMode.syncThenHydrate;

    Future<bool> hydrate() async {
      if (!shouldHydrate || !persistencePolicy.enabled) return false;

      final snapshot = await _persistence.load<T, Serialized>(
        key,
        codec: codec,
      );
      if (snapshot == null) return false;
      if (snapshot.isExpired && !bootstrapPolicy.allowExpiredHydration) {
        return false;
      }

      await emitData(snapshot.data);
      return true;
    }

    Future<void> syncAndPersist() async {
      if (!shouldSync) return;

      try {
        final loader = sync();
        final synced = bootstrapPolicy.syncTimeout == null
            ? await loader
            : await loader.timeout(bootstrapPolicy.syncTimeout!);

        if (synced == null) return;

        await emitData(synced);

        if (persistencePolicy.enabled) {
          final now = DateTime.now();
          await _persistence.save<T, Serialized>(
            key,
            RepoSnapshot<T>(
              data: synced,
              savedAt: now,
              lastSyncAt: now,
              expiresAt: persistencePolicy.snapshotTtl == null
                  ? null
                  : now.add(persistencePolicy.snapshotTtl!),
            ),
            codec: codec,
          );
        }
      } catch (e, st) {
        if (bootstrapPolicy.failureBehavior ==
            SyncFailureBehavior.emitErrorState) {
          await emitError(e, st);
        }
      }
    }

    if (bootstrapPolicy.mode == BootstrapHydrationMode.hydrateThenSync) {
      await hydrate();
      if (bootstrapPolicy.syncAfterHydration) {
        await syncAndPersist();
      }
      return;
    }

    if (bootstrapPolicy.mode == BootstrapHydrationMode.syncThenHydrate) {
      final before = repo.state;
      await syncAndPersist();
      if (!before.hasData && repo.state.hasData == false) {
        await hydrate();
      }
      return;
    }

    if (bootstrapPolicy.mode == BootstrapHydrationMode.hydrateOnly) {
      await hydrate();
      return;
    }

    await syncAndPersist();
  }

  @override
  Future<void> destroy() async {}

  @override
  String get logTag => 'DefaultRepoBootstrapService';
}
