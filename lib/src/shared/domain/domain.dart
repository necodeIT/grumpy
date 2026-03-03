export 'datasources/datasources.dart';
export 'errors/errors.dart';
export 'models/models.dart';
export 'services/services.dart';

import 'package:get_it/get_it.dart' hide Disposable;

/// Base contract for DI-managed types.
///
/// Concrete implementations can control their registration behavior in
/// [Module.bindServices] and [Module.bindDatasources] through [singelton]:
/// if `true`, modules register them as lazy singletons; if `false`, modules
/// register them as factories.
///
/// {@category shared}

abstract class Injectable {
  /// Creates an injectable DI contract.
  const Injectable();

  /// Whether this type should be resolved as a singleton in module DI binding.
  ///
  /// Used by module injectable binding:
  /// - `true` => [GetIt.registerLazySingleton]
  /// - `false` => [GetIt.registerFactory]
  bool get singelton;
}
