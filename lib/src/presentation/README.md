# Presentation

`presentation` contains UI-facing composition primitives and adapters used by consuming apps. It exists to keep application-facing route and middleware APIs easy to import without exposing internal wiring details from lower-level features.

In practice, this layer mostly re-exports route-linked view types and middleware contracts, keeps presentation code consuming repos as facades instead of reaching into infra details, and provides barrels that are friendlier for application code than deep feature-path imports. The key generics are `T`, the presentation type rendered for a route, and `Config`, the app configuration object shared with routing and modules.

This layer should adapt lower-level features for app code rather than turn into a second domain layer. Middleware here should stay orchestration-focused, and feature policy should still live in `repo`, `cache`, `persistence`, `transactions`, and `routing`.

For example:

```dart
final middleware = <Middleware<Object, AppConfig>>[
  AuthMiddleware(),
];
```
