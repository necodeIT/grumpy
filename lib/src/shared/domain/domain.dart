export 'datasources/datasources.dart';
export 'errors/errors.dart';
export 'models/models.dart';
export 'services/services.dart';

import 'package:get_it/get_it.dart' hide Disposable;

/// Base contract for DI-managed types.
///
/// Defines the minimum contract a type must satisfy to participate in module DI.
///
/// Modules need one shared way to decide whether a type is registered as a
/// singleton or as a factory.
///
/// Concrete implementations expose [singelton], which [Module] reads while
/// binding services and datasources.
///
/// Repositories are handled separately by module DI and are always treated as
/// async singletons regardless of this contract.
///
/// This type has no generic parameters. The important configuration point is
/// [singelton].
///
/// For example:
/// ```dart
/// class ClockService extends Service {
///   @override
///   bool get singelton => true;
/// }
/// ```
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
