import 'dart:async';
import 'package:grumpy/grumpy.dart';

/// Details about a stored payload/schema mismatch.
///
/// Describes the stored payload that failed schema validation or decoding.
///
/// Cache and persistence layers need enough context to decide whether a bad
/// payload can be migrated, ignored, or evicted.
///
/// The context captures the storage key, expected schema, discovered schema,
/// optional payload, compatibility version, and underlying error.
///
/// [foundSchemaId] can be `null` when a payload lacks embedded schema metadata.
///
/// - `Serialized`: the stored payload type.
/// - [storageKey], [expectedSchemaId], [foundSchemaId], [serializedPayload].
///
/// For example:
/// ```dart
/// SchemaMismatchContext<Uint8List>(
///   storageKey: key.asStorageKey(),
///   expectedSchemaId: 'settings_v2',
///   foundSchemaId: 'settings_v1',
/// );
/// ```
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
/// Tells the caller whether to evict, ignore, or attempt to decode a mismatched
/// payload anyway.
///
/// Schema mismatches are not always fatal; some payloads can be migrated or
/// treated as cache misses safely.
///
/// The decision exposes eviction, miss-handling, and optional decode-fallback
/// flags together with an optional patched payload.
///
/// `allowDecodeFallback` only matters when the caller still intends to attempt
/// a decode after mismatch handling.
///
/// - `Serialized`: the stored payload type.
/// - [evict], [treatAsMiss], [allowDecodeFallback], [patchedSerializedPayload].
///
/// For example:
/// ```dart
/// const SchemaMismatchDecision<Uint8List>(
///   evict: true,
///   treatAsMiss: true,
/// );
/// ```
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
/// Defines the callback type used to resolve schema mismatches.
///
/// Repos may need custom migration behavior without hard-coding it into the
/// storage layer.
///
/// The callback receives a [SchemaMismatchContext] and returns a
/// [SchemaMismatchDecision].
///
/// Resolvers may be sync or async.
///
/// - `Serialized`: the payload type being inspected.
///
/// For example:
/// ```dart
/// Future<SchemaMismatchDecision<Uint8List>> resolve(
///   SchemaMismatchContext<Uint8List> context,
/// ) async => const SchemaMismatchDecision();
/// ```
///
/// {@category persistence}

typedef SchemaMismatchResolver<Serialized extends Object> =
    FutureOr<SchemaMismatchDecision<Serialized>> Function(
      SchemaMismatchContext<Serialized> context,
    );
