import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

/// Shared logging helper for runtime objects.
///
/// Provides a consistent logger name and convenience logging methods.
///
/// Grumpy types should emit logs that are easy to filter by feature and type.
///
/// Logger names are built from [group] and [logTag], and [log] chooses between
/// [logLevel] and [errorLogLevel] depending on whether an error is present.
///
/// Override [logTag] with a hard-coded string if you target minified runtimes.
///
/// For example:
/// ```dart
/// class Worker with LogMixin {
///   @override
///   String get group => 'Worker';
/// }
/// ```
///
/// {@category shared}

mixin class LogMixin {
  Logger get _logger => Logger('${group.isNotEmpty ? '$group.' : ''}$logTag');

  /// The tag used for logging, typically the class name.
  /// Defaults to the runtime type of the class.
  ///
  /// It is recommended to override this getter to a harder-coded string if targeting
  /// minified environments where [runtimeType] may be obfuscated.
  @mustBeOverridden
  String get logTag => runtimeType.toString();

  /// The parent logging group for this class.
  String get group => '';

  /// Logs a message with an optional error and stack trace.
  /// If an error is provided, it logs at [errorLogLevel], otherwise at [logLevel].
  void log(Object message, [Object? error, StackTrace? stackTrace]) {
    _logger.log(
      error != null ? errorLogLevel : logLevel,
      message,
      error,
      stackTrace,
    );
  }

  /// Logs a message at the specified [level] with an optional error and stack trace.
  ///
  /// This method is intended for internal use.
  @internal
  void logAtLevel(
    Level level,
    Object message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    _logger.log(level, message, error, stackTrace);
  }

  /// The log level used for regular messages.
  /// Defaults to [Level.INFO].
  Level get logLevel => Level.INFO;

  /// The log level used for error messages.
  /// Defaults to [Level.SEVERE].
  Level get errorLogLevel => Level.SEVERE;
}
