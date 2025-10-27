import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:modular_foundation/modular_foundation.dart';

/// A service is responsible for IO operations, such as making network requests
/// or reading/writing files.
abstract class Service with LogMixin implements Disposable {
  @nonVirtual
  @override
  String get group => 'Service';

  @nonVirtual
  @override
  Level get logLevel => Level.FINEST;

  @nonVirtual
  @override
  Level get errorLogLevel => Level.WARNING;
}
