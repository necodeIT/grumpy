import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:modular_foundation/modular_foundation.dart';

// this is the base class.
// ignore: datasources_must_extend_datasource
/// A datasource is responsible for providing data from a specific source,
/// such as a database, API, or local storage.
abstract class Datasource with LogMixin, Disposable {
  /// A datasource is responsible for providing data from a specific source,
  /// such as a database, API, or local storage.
  const Datasource();

  @nonVirtual
  @override
  String get group => 'Datasource';

  @nonVirtual
  @override
  Level get logLevel => Level.FINER;

  @nonVirtual
  @override
  Level get errorLogLevel => Level.WARNING;
}
