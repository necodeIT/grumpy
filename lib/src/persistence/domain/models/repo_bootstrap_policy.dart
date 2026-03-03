import 'package:grumpy/grumpy.dart';

/// Startup bootstrap order.
///
/// {@category persistence}

enum BootstrapHydrationMode {
  /// Try snapshot hydration first, then synchronize from remote.
  hydrateThenSync,

  /// Synchronize first, then fall back to snapshot hydration.
  syncThenHydrate,

  /// Only hydrate from snapshot storage.
  hydrateOnly,

  /// Only synchronize from remote.
  syncOnly,
}

/// Sync-failure behavior when hydration already succeeded.
///
/// {@category persistence}

enum SyncFailureBehavior {
  /// Keep hydrated data visible and suppress repo error state.
  keepHydratedData,

  /// Emit repo error state when sync fails.
  emitErrorState,

  /// Suppress sync failures and do not modify state.
  silent,
}

/// Repo bootstrap controls.
///
/// This policy defines startup behavior for repos that use
/// [PersistentRepoStateMixin] and [RepoBootstrapService].
///
/// Example:
/// - fast startup with local snapshot then refresh:
///   `RepoBootstrapPolicy(mode: BootstrapHydrationMode.hydrateThenSync)`
/// - network-first:
///   `RepoBootstrapPolicy(mode: BootstrapHydrationMode.syncThenHydrate)`
/// - local-only mode:
///   `RepoBootstrapPolicy(mode: BootstrapHydrationMode.hydrateOnly)`
///
/// {@category persistence}

class RepoBootstrapPolicy extends Model {
  /// Creates bootstrap behavior options for startup hydration/sync.
  const RepoBootstrapPolicy({
    /// Bootstrap execution mode.
    this.mode = BootstrapHydrationMode.hydrateThenSync,

    /// When hydrating first, also run sync afterward.
    this.syncAfterHydration = true,

    /// Allows expired snapshots to hydrate as a fallback.
    this.allowExpiredHydration = true,

    /// Optional timeout for remote sync.
    this.syncTimeout,

    /// How to behave when sync fails.
    this.failureBehavior = SyncFailureBehavior.keepHydratedData,
  });

  /// Bootstrap execution mode.
  final BootstrapHydrationMode mode;

  /// When hydrating first, also run sync afterward.
  final bool syncAfterHydration;

  /// Allows expired snapshots to hydrate as a fallback.
  final bool allowExpiredHydration;

  /// Optional timeout for remote sync.
  final Duration? syncTimeout;

  /// How to behave when sync fails.
  final SyncFailureBehavior failureBehavior;
}
