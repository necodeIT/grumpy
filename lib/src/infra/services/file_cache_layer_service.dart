import 'dart:convert';
import 'dart:io';

import 'package:grumpy/grumpy.dart';

/// Default file-backed cache layer implementation.
///
/// Storage model:
/// - each cache key maps to one JSON file
/// - filename is base64url(storageKey) to avoid filesystem-invalid characters
/// - corrupted payloads are deleted eagerly and treated as cache misses
class LocalFileCacheLayerService extends FileCacheLayerService {
  /// Creates a file-backed cache layer.
  ///
  /// When [baseDir] is omitted, a process-temporary directory is used.
  LocalFileCacheLayerService({Directory? baseDir})
    : _baseDir =
          baseDir ?? Directory('${Directory.systemTemp.path}/grumpy_cache'),
      super.internal();

  final Directory _baseDir;

  Future<File> _fileForKey(StorageKey key) async {
    if (!await _baseDir.exists()) {
      await _baseDir.create(recursive: true);
    }

    final safe = base64Url.encode(utf8.encode(key.asStorageKey()));
    return File('${_baseDir.path}/$safe.json');
  }

  @override
  Future<CacheEntry<T>?> read<T, Serialized extends Object>(
    CacheKey<T> key, {
    SerializationCodec<T, Serialized>? codec,
  }) async {
    final file = await _fileForKey(key);
    if (!await file.exists()) return null;

    try {
      final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final payload = map['payload'];
      final createdAt = DateTime.parse(map['createdAt'] as String);
      final expiresAtRaw = map['expiresAt'];
      final expiresAt = expiresAtRaw == null
          ? null
          : DateTime.parse(expiresAtRaw as String);
      final etag = map['etag'] as String?;

      late final T value;
      if (codec != null) {
        value = codec.decode(payload as Serialized);
      } else {
        value = payload as T;
      }

      final entry = CacheEntry<T>(
        value: value,
        createdAt: createdAt,
        expiresAt: expiresAt,
        etag: etag,
      );

      if (entry.isExpired) {
        await file.delete();
        return null;
      }

      return entry;
    } catch (_) {
      await file.delete();
      return null;
    }
  }

  @override
  Future<void> write<T, Serialized extends Object>(
    CacheKey<T> key,
    CacheEntry<T> entry, {
    SerializationCodec<T, Serialized>? codec,
  }) async {
    final file = await _fileForKey(key);

    final payload = codec != null ? codec.encode(entry.value) : entry.value;

    final map = <String, Object?>{
      'payload': payload,
      'createdAt': entry.createdAt.toIso8601String(),
      'expiresAt': entry.expiresAt?.toIso8601String(),
      'etag': entry.etag,
    };

    await file.writeAsString(jsonEncode(map));
  }

  @override
  Future<void> invalidate<T>(CacheKey<T> key) async {
    final file = await _fileForKey(key);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> clearNamespace(String namespace) async {
    if (!await _baseDir.exists()) return;

    await for (final entity in _baseDir.list()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last.replaceFirst('.json', '');
      final decoded = utf8.decode(base64Url.decode(name));
      if (decoded.startsWith('$namespace|')) {
        await entity.delete();
      }
    }
  }

  @override
  Future<void> free() async {}

  @override
  String get logTag => 'LocalFileCacheLayerService';
}
