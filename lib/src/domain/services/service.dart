import 'package:get_it/get_it.dart' hide Disposable;
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:grumpy/grumpy.dart';

// this is the base class.
// ignore: services_must_extend_service
/// A service is responsible for IO operations, such as making network requests
/// or reading/writing files.
abstract class Service with LogMixin, Disposable, TelemetryMixin {
  /// A service is responsible for IO operations, such as making network requests
  /// or reading/writing files.
  const Service();

  @override
  String get group => 'Service';

  @nonVirtual
  @override
  Level get logLevel => Level.FINEST;

  @nonVirtual
  @override
  Level get errorLogLevel => Level.WARNING;

  /// Retrieves an instance of the specified [Service] type from the service locator.
  static S get<S extends Service>() => GetIt.instance<S>();
}
