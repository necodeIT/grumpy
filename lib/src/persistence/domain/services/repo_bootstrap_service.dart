import 'dart:async';

import 'package:grumpy/grumpy.dart';

/// {@template repo_bootstrap_data_type}
/// The type parameter `T` is the repo data type being synchronized.
/// {@endtemplate}
///
/// {@template repo_bootstrap_serialized_type}
/// `Serialized` is the persisted payload type used by the snapshot codec and
/// persistence service.
/// {@endtemplate}
///
/// Async callback that fetches latest remote repo state.
///
/// Defines the remote sync callback used during bootstrap.
///
/// The bootstrap service should orchestrate repo startup without knowing how a
/// specific repo fetches remote data.
///
/// The callback returns the latest repo payload or `null` when sync should not
/// update state.
///
/// Returning `null` is treated differently from throwing an error.
///
/// {@macro repo_bootstrap_data_type}
///
/// For example:
/// ```dart
/// Future<SettingsState?> sync() => datasource.fetchSettings();
/// ```
///
/// {@category persistence}

typedef RepoSyncLoader<T> = Future<T?> Function();

/// Coordinates repo hydration + sync sequence.
///
/// Executes one repo's startup strategy across local hydration, remote sync,
/// failure handling, and optional persistence of refreshed state.
///
/// Startup data behavior is complex enough that it should be centralized rather
/// than reimplemented in every repo.
///
/// [bootstrap] combines [RepoPersistencePolicy], [RepoBootstrapPolicy], a
/// [RepoSyncLoader], and repo emitters into one orchestration call.
///
/// Most repos should reach this service through [PersistentRepoStateMixin].
///
/// {@macro repo_bootstrap_data_type}
/// {@macro repo_bootstrap_serialized_type}
/// The remaining collaborators are [repo], [key], [codec], [sync], [emitData],
/// and [emitError].
///
/// For example:
/// ```dart
/// final bootstrap = RepoBootstrapService();
/// ```
///
/// {@category persistence}

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
