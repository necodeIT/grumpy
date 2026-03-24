import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:grumpy/grumpy.dart';

part 'telemetry_context.freezed.dart';

/// Represents a telemetry span’s execution context.
///
/// Carries the active backend span and related metadata through async work.
///
/// Telemetry backends need one transport object for zone-based context
/// propagation.
///
/// [TelemetryContext] stores the backend-native [span], arbitrary [attributes],
/// and the [ownerType] of the telemetry service that created it.
///
/// This type is mainly for telemetry infrastructure code rather than app-level
/// feature logic.
///
/// - `T`: the backend-native span type.
/// - [span], [attributes], [ownerType]: active span context metadata.
///
///
/// ## Purpose
/// A [TelemetryContext] enables:
/// - Accessing the current active span
/// - Tracking the service type that owns the span
/// - Passing optional contextual metadata (e.g., trace IDs, parent IDs)
///
///
/// ## Generic type parameter
/// The generic type [T] represents the backend’s native span or transaction
/// object. For example:
///
/// ```dart
/// TelemetryContext<ISpan> // Sentry span
/// TelemetryContext<Span>  // OpenTelemetry span
/// ```
///
/// This type is never exposed outside the infrastructure layer and should be
/// used internally by the telemetry service implementation only.
///
///
/// ## Zone ownership
/// Each context tracks the [TelemetryContext.ownerType] of the service that created it.
/// This prevents nested spans from different telemetry backends from
/// accidentally attaching to each other.
///
/// {@category telemetry}

@freezed
abstract class TelemetryContext<T> extends Model with _$TelemetryContext<T> {
  /// Creates a new [TelemetryContext].
  const factory TelemetryContext({
    /// The backend-specific span object (e.g., a Sentry or OTel span).
    required T span,

    /// Arbitrary metadata or contextual data for this span.
    ///
    /// Implementations may store trace IDs, sampling info, etc.
    required Map<Symbol, dynamic> attributes,

    /// The type of the [TelemetryService] that owns this context.
    ///
    /// Used to ensure type-safe context lookups in [TelemetryZoneMixin].
    required Type ownerType,
  }) = _TelemetryContext<T>;
  const TelemetryContext._();
}
