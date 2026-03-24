# Repo

`repo` defines the reactive state boundary used by higher layers. It owns `Repo<T>`, the `RepoState<T>` family, and the repo-to-repo composition helpers that let one repo derive its state from others without reimplementing dependency tracking each time.

The point of the feature is to give presentation code a stable contract for state, loading, and errors while keeping cache policy, mutation policy, and persistence concerns in their own features. `Repo<T>` is the core stream-backed holder, `RepoState<T>` makes state transitions explicit instead of nullable, and `UseRepoMixin` and `DeferredRepoMixin` rebuild derived state when upstream repos or external signals change.

The main thing to keep in mind is that a repo can exist before it has data, so consumers should expect `RepoState.loading()` on startup. `T` is the visible data shape owned by the repo, and `D`, `E`, and `L` in `UseRepoMixin` describe the derived data, error, and loading payloads produced from dependencies. If you use `UseRepoMixin`, call `installUseRepoHooks()` in the constructor.

For example:

```dart
class CounterRepo extends Repo<int> {
  CounterRepo() {
    data(0);
  }

  void increment() => data(state.requireData + 1);
}
```
