import 'dart:async';

import 'package:grumpy_annotations/grumpy_annotations.dart';
import 'package:grumpy/grumpy.dart';

/// Adds repo snapshot persistence + startup bootstrap behavior.
///
/// This mixin coordinates:
/// - startup hydration + remote sync via [RepoBootstrapService]
/// - debounced snapshot saves via [RepoStatePersistenceService]
///
/// Opt-in contract:
/// - implement [snapshotKey], [snapshotCodec], and [syncFromRemote]
/// - optionally override [persistencePolicy] / [bootstrapPolicy]
/// - call [installRepoStatePersistenceHooks] in constructor
///
/// Typical flow per activation:
/// 1. bootstrap service attempts hydrate/sync by policy
/// 2. `data(...)` emissions are saved as snapshots (debounced) when enabled
/// 3. deactivation resets bootstrap guard for next activation cycle
///
/// {@category persistence}

mixin PersistentRepoStateMixin<T, Serialized extends Object>
    on Repo<T>, RepoLifecycleHooksMixin<T>, TelemetryMixin {
  bool _installed = false;
  bool _bootstrappedForActivation = false;
  Future<void>? _bootstrapFuture;
  Timer? _persistDebounce;

  /// Persistence defaults for this repo.
  ///
  /// Override to enable persistence and customize TTL/debounce behavior.
  RepoPersistencePolicy<Serialized> get persistencePolicy =>
      RepoPersistencePolicy<Serialized>();

  /// Bootstrap defaults for this repo.
  ///
  /// Override to control hydrate/sync order and failure behavior.
  RepoBootstrapPolicy get bootstrapPolicy => const RepoBootstrapPolicy();

  /// Snapshot key used for persistence operations.
  ///
  /// Keep this stable across app launches for same repo scope.
  StorageKey get snapshotKey;

  /// Codec used for snapshot serialization.
  ///
  /// Should remain backward compatible across schema revisions when possible.
  SerializationCodec<T, Serialized> get snapshotCodec;

  /// Remote sync loader called during bootstrap.
  ///
  /// Return `null` when remote sync should not update repo data.
  Future<T?> syncFromRemote();

  @mustCallInConstructor
  /// Installs lifecycle hooks for bootstrap + snapshot persistence.
  ///
  /// This method is idempotent.
  void installRepoStatePersistenceHooks() {
    if (_installed) return;
    _installed = true;

    onActivate(() async {
      await _bootstrap();
    });

    onDeactivate(() {
      _bootstrappedForActivation = false;
    });

    onData((value) {
      if (!persistencePolicy.enabled || !persistencePolicy.persistOnData) {
        return;
      }
      if (!persistencePolicy.saveNullData && value == null) {
        return;
      }

      _persistDebounce?.cancel();
      _persistDebounce = Timer(persistencePolicy.persistDebounce, () async {
        await _saveSnapshot(value);
      });
    });

    onDisposed(() async {
      _persistDebounce?.cancel();
      _persistDebounce = null;
    });
  }

  Future<void> _bootstrap() async {
    if (_bootstrappedForActivation) return;

    _bootstrapFuture ??= RepoBootstrapService()
        .bootstrap<T, Serialized>(
          repo: this,
          key: snapshotKey,
          codec: snapshotCodec,
          persistencePolicy: persistencePolicy,
          bootstrapPolicy: bootstrapPolicy,
          sync: syncFromRemote,
          emitData: (value) => data(value),
          emitError: (error, st) => this.error(error, st),
        )
        .whenComplete(() {
          _bootstrapFuture = null;
          _bootstrappedForActivation = true;
        });

    await _bootstrapFuture;
  }

  Future<void> _saveSnapshot(T value) async {
    if (!persistencePolicy.saveNullData && value == null) {
      return;
    }

    final now = DateTime.now();
    await RepoStatePersistenceService().save<T, Serialized>(
      snapshotKey,
      RepoSnapshot<T>(
        data: value,
        savedAt: now,
        expiresAt: persistencePolicy.snapshotTtl == null
            ? null
            : now.add(persistencePolicy.snapshotTtl!),
      ),
      codec: snapshotCodec,
    );
  }
}
