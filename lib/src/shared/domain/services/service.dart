import 'package:get_it/get_it.dart' hide Disposable;
import 'package:grumpy_annotations/grumpy_annotations.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:grumpy/grumpy.dart';

// this is the base class.
// ignore: services_must_extend_service
/// Base contract for side-effecting services.
///
/// Defines the shared runtime behavior for services that perform work such as
/// network access, file IO, crypto, time, or other non-UI orchestration.
///
/// Services need a common DI, logging, telemetry, and disposal contract so
/// features can swap implementations cleanly.
///
/// [Service] mixes in [LogMixin], [Disposable], and [TelemetryMixin], and lets
/// subclasses control DI lifetime through [singelton].
///
/// A service may be pure or side-effecting, but it should still represent
/// runtime behavior rather than a value object.
///
/// None on the base type.
///
/// For example:
/// ```dart
/// abstract class ClockService extends Service {
///   const ClockService();
///
///   DateTime now();
/// }
/// ```
///
/// {@category shared}

@BaseClass(allowedLayers: {.domain, .infra})
abstract class Service
    with LogMixin, Disposable, TelemetryMixin
    implements Injectable {
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

  @override
  bool get singelton => false;
}
