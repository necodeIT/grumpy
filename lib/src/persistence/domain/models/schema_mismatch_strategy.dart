import 'dart:async';
import 'package:grumpy/grumpy.dart';

/// Details about a stored payload/schema mismatch.
///
/// {@category persistence}

class SchemaMismatchContext<Serialized extends Object> extends Model {
  /// Creates schema mismatch context details.
  const SchemaMismatchContext({
    /// Full storage key for the payload under inspection.
    required this.storageKey,

    /// Schema expected by current runtime.
    required this.expectedSchemaId,

    /// Schema found in persisted payload, if present.
    required this.foundSchemaId,

    /// Original serialized payload, when available.
    this.serializedPayload,

    /// Optional compatibility version channel.
    this.compatVersion,

    /// Underlying decode/parse error, if any.
    this.error,
  });

  /// Full storage key for the payload under inspection.
  final String storageKey;

  /// Schema expected by current runtime.
  final String expectedSchemaId;

  /// Schema found in persisted payload, if present.
  final String? foundSchemaId;

  /// Original serialized payload, when available.
  final Serialized? serializedPayload;

  /// Optional compatibility version channel.
  final int? compatVersion;

  /// Underlying decode/parse error, if any.
  final Object? error;
}

/// Resolver outcome for mismatched payloads.
///
/// {@category persistence}

class SchemaMismatchDecision<Serialized extends Object> extends Model {
  /// Creates the resolver decision for a schema mismatch.
  const SchemaMismatchDecision({
    /// Deletes invalid stored payload when enabled.
    this.evict = true,

    /// Continues caller flow as a normal cache miss when enabled.
    this.treatAsMiss = true,

    /// Allows decode fallback using original/patched payload.
    this.allowDecodeFallback = false,

    /// Optional patched payload used for fallback decode.
    this.patchedSerializedPayload,
  });

  /// Deletes invalid stored payload when enabled.
  final bool evict;

  /// Continues caller flow as a normal cache miss when enabled.
  final bool treatAsMiss;

  /// Allows decode fallback using original/patched payload.
  final bool allowDecodeFallback;

  /// Optional patched payload used for fallback decode.
  final Serialized? patchedSerializedPayload;
}

/// Async mismatch resolver hook.
///
/// {@category persistence}

typedef SchemaMismatchResolver<Serialized extends Object> =
    FutureOr<SchemaMismatchDecision<Serialized>> Function(
      SchemaMismatchContext<Serialized> context,
    );
