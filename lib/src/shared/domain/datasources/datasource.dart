import 'package:get_it/get_it.dart' hide Disposable;
import 'package:grumpy_annotations/grumpy_annotations.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:grumpy/grumpy.dart';

/// A datasource is responsible for providing data from a specific source,
/// such as a database, API, or local storage.
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
