# Module

`module` is the runtime composition layer. It defines how features are wired, scoped in DI, and activated, deactivated, and destroyed as units so that feature code can stay focused on behavior instead of bootstrap details.

The feature exists to keep dependency wiring and lifecycle orchestration out of repos and services. `Module<RouteType, Config>` describes bindings and routes for one feature, `RootModule<RouteType, Config>` provides app-wide defaults for routing, telemetry, cache, persistence, and transactions, and `ModuleRegistryService` keeps the active module graph canonical and synchronized. Each module gets its own DI scope, and that scope is removed during `destroy()`.

`RouteType` is the presentation type returned by the module's routes, `Config` is the configuration object passed into binding builders, and helper types like `Bind<Base, Config>` and `InjectableFactory<T, Config>` define how registrations are expressed. The main lifecycle order is `initialize -> activate -> deactivate -> destroy`, lifecycle-managed injectables must be singletons, and modules themselves should stay focused on composition rather than feature logic.

For example:

```dart
class SettingsModule extends Module<Object, AppConfig> {
  @override
  void bindRepos(Bind<Repo, AppConfig> bind) {
    bind<SettingsRepo>((cfg, resolve) => SettingsRepo(resolve()));
  }

  @override
  List<Route<Object, AppConfig>> get routes => const [];
}
```
