import 'package:meta/meta.dart';
import 'package:modular_foundation/modular_foundation.dart';

/// Represents a telemetry span’s execution context.
///
/// Each [TelemetryContext] holds the active backend-specific span and
/// associated metadata for the current tracing zone.
///
/// Contexts are stored inside [Zone]s using the [`TelemetryZoneMixin`].
/// This allows automatic propagation of telemetry information across
/// asynchronous boundaries without having to manually pass objects around.
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
/// Each context tracks the [ownerType] of the service that created it.
/// This prevents nested spans from different telemetry backends from
/// accidentally attaching to each other.
@immutable
class TelemetryContext<T> implements Model {
  /// Creates a new [TelemetryContext].
  const TelemetryContext({
    required this.span,
    required this.ownerType,
    this.attributes = const {},
  });

  /// The backend-specific span object (e.g., a Sentry or OTel span).
  final T span;

  /// Arbitrary metadata or contextual data for this span.
  ///
  /// Implementations may store trace IDs, sampling info, etc.
  final Map<Symbol, dynamic> attributes;

  /// The type of the [TelemetryService] that owns this context.
  ///
  /// Used to ensure type-safe context lookups in [TelemetryZoneMixin].
  final Type ownerType;
}
