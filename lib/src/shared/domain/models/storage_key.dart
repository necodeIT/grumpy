import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:grumpy/grumpy.dart';

part 'storage_key.freezed.dart';
part 'storage_key.g.dart';

/// Stable storage key contract shared by cache and snapshot persistence layers.
@freezed
abstract class StorageKey with _$StorageKey implements Model {
  /// Stable storage key contract shared by cache and snapshot persistence layers.
  const factory StorageKey({
    /// Logical namespace partition.
    required String namespace,

    /// Stable identifier inside [namespace].
    required String primaryKey,

    /// Serialized-shape fingerprint.
    required String schemaId,

    /// Optional manual compatibility version.
    int? compatVersion,
  }) = _StorageKey;
  const StorageKey._();

  /// Creates a [StorageKey] from a string produced by [asStorageKey].
  factory StorageKey.parse(String storageKey) {
    final decoded = utf8.decode(base64Url.decode(storageKey));
    final json = jsonDecode(decoded);
    if (json is! Map) {
      throw const FormatException('Invalid storage key format.');
    }
    return StorageKey.fromJson(Map<String, Object?>.from(json));
  }

  /// Creates a [StorageKey] from JSON.
  factory StorageKey.fromJson(Map<String, dynamic> json) =>
      _$StorageKeyFromJson(json);

  /// Parses [storageKey] into a [StorageKey], or returns `null` if invalid.
  ///
  /// If you want to throw on invalid keys, use [StorageKey.parse] directly.
  static StorageKey? parseOrNull(String storageKey) {
    try {
      return StorageKey.parse(storageKey);
    } catch (_) {
      return null;
    }
  }

  /// A stable reversable base64 string representation of this key, suitable for storage and filenames.
  ///
  /// Use [StorageKey.parse] to convert back to a [StorageKey] instance.
  String asStorageKey() {
    final json = toJson();

    return jsonEncode(json).convert.toBase64();
  }
}
