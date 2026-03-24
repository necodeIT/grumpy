# Shared

`shared` contains the cross-cutting primitives that every other feature depends on: base DI contracts, lifecycle hooks, logging, serialization helpers, and shared errors and models. It exists so features can agree on the same lifecycle and type conventions without duplicating boilerplate or drifting into incompatible abstractions.

The package does this by defining a small set of stable building blocks. `Injectable` controls DI registration behavior through `singelton`, `LifecycleMixin` and `LifecycleHooksMixin` normalize `initialize`, `activate`, `deactivate`, `dependenciesChanged`, and `destroy`, `LogMixin` gives consistent logger grouping, and `SerializationCodec<Data, Serialized>` keeps storage and wire conversions typed.

Keep this package small: if something belongs to only one feature, it probably does not belong here. `Data` and `Serialized` on `SerializationCodec` describe runtime and persisted shapes, and `T` on models, repos, and helpers represents a feature-specific payload. Also, the teardown lifecycle method is `destroy`, not `free`.

For example:

```dart
const userCodec = SerializationCodec<User, JsonMap>.call(
  encode: (user) => user.toJson(),
  decode: User.fromJson,
);
```
