# Routing

`routing` models routes and navigation behavior, including middleware-driven interception and module activation. It exists so route declarations can stay declarative while the runtime routing engine handles matching, middleware, and lifecycle concerns consistently.

The feature works through `RouteContext`, which stores the parsed navigation request, and the route tree types `Route`, `ModuleRoute`, and `LeafRoute`, which describe how a path should resolve. `RoutingService` is the execution boundary that parses a path, runs middleware, activates required modules, and emits preview and final views, while `Leaf.preview` gives the router a way to show a placeholder before activation completes.

`T` is the presentation type returned to the consumer, `Config` is the configuration object available during route and module activation, and `RouteContext` carries the active path, params, query values, and fragment. The main thing to remember is that `preview()` must stay side-effect free because module-scoped dependencies may not be active yet, middleware should stay orchestration-focused, and runtime routing details belong in `infra/`.

For example:

```dart
const Route<Object, AppConfig> settingsRoute = LeafRoute<Object, AppConfig>(
  path: '/settings',
  view: SettingsLeaf(),
);
```
