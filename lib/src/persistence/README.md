# Persistence

`persistence` handles repo snapshot durability and activation-time hydration and synchronization. It exists so restart survival, warm boot behavior, and remote resynchronization do not have to be implemented independently inside every repo.

The feature is built around a few cooperating pieces. `RepoSnapshot<T>` stores typed data plus timestamps and metadata, `RepoStatePersistenceService` owns durable storage, `RepoBootstrapService` coordinates hydrate and sync behavior from `RepoBootstrapPolicy`, and `PersistentRepoStateMixin` hooks repo activation and `data(...)` emissions into that flow.

Persistence is opt-in, so a repo needs to provide a stable `StorageKey`, a `snapshotCodec`, and a `syncFromRemote` implementation before any of this is useful. `RepoPersistencePolicy` controls write behavior, debounce, TTL, and corruption handling, while `RepoBootstrapPolicy` controls hydration mode, timeout, and sync failure behavior. Bootstrap runs once per activation cycle and resets on `deactivate()`, and schema changes should be managed through `schemaId`, `compatVersion`, and mismatch resolvers.

For example:

```dart
class SettingsRepo extends Repo<SettingsState>
    with RepoLifecycleMixin<SettingsState>,
         RepoLifecycleHooksMixin<SettingsState>,
         TelemetryMixin,
         PersistentRepoStateMixin<SettingsState, Uint8List> {
  SettingsRepo() {
    installRepoStatePersistenceHooks();
  }
}
```
