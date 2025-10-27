import 'dart:async';
import 'package:meta/meta.dart';
import 'package:modular_foundation/modular_foundation.dart';

/// A reusable mixin that provides zone-based span management for telemetry services.
///
/// This mixin encapsulates all the logic required to:
/// - Start new spans in isolated [Zone]s
/// - Propagate the active span context across async boundaries
/// - Ensure spans are only resumed by the same telemetry service type
///
///
/// ## Intended usage
/// Extend your concrete telemetry backend with this mixin to gain
/// consistent zone management behavior:
///
/// ```dart
/// class SentryTelemetryService extends TelemetryService with TelemetryZoneMixin<ISpan> {
///
///   @override
///   Future<void> recordEvent(String name, {Map<String, String>? attributes}) async {
///     Sentry.captureMessage(name);
///   }
///
///   @override
///   Future<void> recordException(Object error, [StackTrace? stackTrace]) async {
///     await Sentry.captureException(error, stackTrace: stackTrace);
///   }
///
///   @override
///   Future<ISpan> onStartSpan(String name,
///       {Map<String, String>? attributes, TelemetryContext<ISpan>? parent}) async {
///     return Sentry.startTransaction(name, 'operation');
///   }
///
///   @override
///   Future<void> onEndSpan(ISpan span, [Object? error]) async {
///     span.finish(status: error == null ? SpanStatus.ok() : SpanStatus.internalError());
///   }
///
///   @override
///   void onAddAttribute(ISpan span, String key, String value) {
///     span.setTag(key, value);
///   }
/// }
/// ```
///
///
/// ## Responsibilities
/// This mixin does not define any backend-specific logic. Instead, it calls the
/// following abstract methods that must be implemented by subclasses:
///
/// - [onStartSpan] → create and start a new backend span
/// - [onEndSpan] → finish or export a span
/// - [onAddAttribute] → attach an attribute to the span
///
/// These are called automatically by [runSpanWithZone] and [addSpanAttribute].
///
/// ## Related
/// - [TelemetryService] — for the high-level telemetry interface
/// - [TelemetryContext] — for the span execution context model
///
/// See also:
///  - [AnalyticsService] for user behavior tracking.
mixin TelemetryZoneMixin<T> on TelemetryService {
  /// The unique key used to store telemetry context in a [Zone].
  static final Symbol _zoneKey = #ctx;

  /// Returns the current [TelemetryContext] for this telemetry service, if any.
  ///
  /// Ensures that the retrieved context was created by the same service type
  /// to prevent cross-service interference.
  @protected
  TelemetryContext<T>? getContext() {
    final ctx = Zone.current[_zoneKey] as TelemetryContext<T>?;
    if (ctx == null) return null;
    if (ctx.ownerType != runtimeType) return null;
    return ctx;
  }

  /// Creates a new [TelemetryContext] for a given backend-specific [span].
  ///
  /// The returned context will be associated with this telemetry service type.
  @protected
  TelemetryContext<T> createContext(
    T span, {
    Map<Symbol, dynamic>? attributes,
  }) {
    return TelemetryContext<T>(
      span: span,
      ownerType: runtimeType,
      attributes: attributes ?? const {},
    );
  }

  /// Starts a new backend span.
  ///
  /// Implementations must return their native span object.
  @protected
  FutureOr<T> onStartSpan(
    String name, {
    Map<String, String>? attributes,
    TelemetryContext<T>? parent,
  });

  /// Ends or exports a span.
  ///
  /// Called automatically when [runSpanWithZone] completes or throws.
  @protected
  FutureOr<void> onEndSpan(T span, [Object? error]);

  /// Called when a new attribute should be added to an active span.
  @protected
  void onAddAttribute(T span, String key, String value);

  /// Executes [callback] inside a new span-scoped [Zone].
  ///
  /// - Automatically starts a new span via [onStartSpan]
  /// - Ensures the span is finished via [onEndSpan]
  /// - Propagates the new [TelemetryContext] using a [Zone]
  ///
  /// This method can be called directly or used to implement
  /// [TelemetryService.runSpan].
  @protected
  Future<R> runSpanWithZone<R>(
    String name,
    FutureOr<R> Function() callback, {
    Map<String, String>? attributes,
  }) async {
    final parent = getContext();
    final span = await onStartSpan(
      name,
      attributes: attributes,
      parent: parent,
    );
    final context = createContext(span);

    late final FutureOr<R> resultFuture;

    runZonedGuarded(
      () {
        resultFuture = callback();
      },
      (error, stack) async {
        // Handle uncaught errors from the callback
        await recordException(error, stack);
        await onEndSpan(span, error);
      },
      zoneValues: {_zoneKey: context},
    );

    try {
      final result = await resultFuture;
      await onEndSpan(span);
      return result;
    } catch (error, stack) {
      await recordException(error, stack);
      await onEndSpan(span, error);
      rethrow;
    }
  }

  @override
  void addSpanAttribute(String key, String value) {
    final ctx = getContext();
    if (ctx == null) return;
    onAddAttribute(ctx.span, key, value);
  }
}
