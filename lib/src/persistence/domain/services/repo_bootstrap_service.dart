import 'dart:async';

import 'package:grumpy/grumpy.dart';

/// Async callback that fetches latest remote repo state.
typedef RepoSyncLoader<T> = Future<T?> Function();

/// Coordinates repo hydration + sync sequence.
///
/// This service is the execution boundary for startup data strategy.
/// It combines:
/// - local snapshot hydration
/// - remote synchronization
/// - failure handling policy
/// - persistence of synchronized state
///
/// Most repos should use this via [PersistentRepoStateMixin] instead of
/// invoking it directly.
abstract class RepoBootstrapService extends Service {
  /// Returns the DI-registered repo bootstrap service.
  factory RepoBootstrapService() => Service.get<RepoBootstrapService>();

  /// Internal constructor for concrete bootstrap implementations.
  RepoBootstrapService.internal();

  /// Runs hydration/sync flow for [repo] using provided policies.
  ///
  /// Implementations should preserve repo semantics:
  /// - emit hydrated data quickly when available
  /// - avoid replacing healthy data with unnecessary errors
  /// - apply [RepoBootstrapPolicy.mode] deterministically
  /// - persist synced payload according to [RepoPersistencePolicy]
  Future<void> bootstrap<T, Serialized extends Object>({
    /// Repo instance being bootstrapped.
    required Repo<T> repo,

    /// Storage key used for snapshot operations.
    required StorageKey key,

    /// Codec used to decode/encode snapshots.
    required SerializationCodec<T, Serialized> codec,

    /// Persistence behavior options.
    required RepoPersistencePolicy<Serialized> persistencePolicy,

    /// Bootstrap hydration/sync behavior options.
    required RepoBootstrapPolicy bootstrapPolicy,

    /// Remote sync loader callback.
    required RepoSyncLoader<T> sync,

    /// Emits hydrated/synced data into repo.
    required FutureOr<void> Function(T value) emitData,

    /// Emits sync failure when policy demands error state.
    required FutureOr<void> Function(Object error, StackTrace? st) emitError,
  });

  @override
  bool get singelton => true;

  @override
  String get group => '${super.group}.RepoBootstrapService';
}
