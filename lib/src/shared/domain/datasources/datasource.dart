import 'package:get_it/get_it.dart' hide Disposable;
import 'package:grumpy_annotations/grumpy_annotations.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:grumpy/grumpy.dart';

/// Base contract for data-access objects.
///
/// Defines the common runtime shape for objects that talk to a concrete data
/// source such as an API, database, or local store.
///
/// Datasources need shared logging, disposal, telemetry, and DI behavior
/// without leaking infrastructure details into higher layers.
///
/// [Datasource] mixes in logging, disposal, and telemetry helpers and exposes a
/// `Service.get`-style resolver via [Datasource.get].
///
/// Domain code should depend on datasource contracts, not concrete infra
/// implementations.
///
/// None on the type itself. Concrete subclasses define their own dependencies.
///
/// For example:
/// ```dart
/// abstract class UserDatasource extends Datasource {
///   const UserDatasource();
///
///   Future<User> fetchUser(String id);
/// }
/// ```
///
/// {@category shared}

@BaseClass(allowedLayers: {.domain, .infra})
abstract class Datasource
    with LogMixin, Disposable, TelemetryMixin
    implements Injectable {
  /// A datasource is responsible for providing data from a specific source,
  /// such as a database, API, or local storage.
  const Datasource();

  @override
  String get group => 'Datasource';

  @nonVirtual
  @override
  Level get logLevel => Level.FINER;

  @nonVirtual
  @override
  Level get errorLogLevel => Level.WARNING;

  /// Retrieves an instance of the specified [Datasource] type from the service locator.
  static D get<D extends Datasource>() => GetIt.instance<D>();

  @override
  bool get singelton => false;
}
