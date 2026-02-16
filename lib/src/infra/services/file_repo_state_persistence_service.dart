import 'dart:convert';
import 'dart:io';

import 'package:grumpy/grumpy.dart';

/// File-backed repo snapshot persistence implementation.
///
/// Storage model:
/// - each [RepoSnapshotKey] maps to one JSON file
/// - filename is base64url(storageKey)
/// - corrupted payloads are deleted and treated as missing snapshots
class FileRepoStatePersistenceService extends RepoStatePersistenceService {
  /// Creates a file-backed snapshot persistence service.
  ///
  /// When [baseDir] is omitted, a process-temporary directory is used.
  FileRepoStatePersistenceService({Directory? baseDir})
    : _baseDir =
          baseDir ??
          Directory('${Directory.systemTemp.path}/grumpy_repo_snapshots'),
      super.internal();

  final Directory _baseDir;

  Future<File> _fileForKey(RepoSnapshotKey key) async {
    if (!await _baseDir.exists()) {
      await _baseDir.create(recursive: true);
    }
    final safe = base64Url.encode(utf8.encode(key.asStorageKey()));
    return File('${_baseDir.path}/$safe.json');
  }

  @override
  Future<RepoSnapshot<T>?> load<T, Serialized extends Object>(
    RepoSnapshotKey key, {
    required SerializationCodec<T, Serialized> codec,
  }) async {
    final file = await _fileForKey(key);
    if (!await file.exists()) return null;

    try {
      final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final payload = map['payload'] as Serialized;
      final savedAt = DateTime.parse(map['savedAt'] as String);
      final expiresAtRaw = map['expiresAt'];
      final lastSyncAtRaw = map['lastSyncAt'];
      final metadataRaw = map['metadata'];

      return RepoSnapshot<T>(
        data: codec.decode(payload),
        savedAt: savedAt,
        expiresAt: expiresAtRaw == null
            ? null
            : DateTime.parse(expiresAtRaw as String),
        lastSyncAt: lastSyncAtRaw == null
            ? null
            : DateTime.parse(lastSyncAtRaw as String),
        metadata: metadataRaw == null
            ? const {}
            : Map<String, Object?>.from(metadataRaw as Map),
      );
    } catch (_) {
      await file.delete();
      return null;
    }
  }

  @override
  Future<void> save<T, Serialized extends Object>(
    RepoSnapshotKey key,
    RepoSnapshot<T> snapshot, {
    required SerializationCodec<T, Serialized> codec,
  }) async {
    final file = await _fileForKey(key);
    final map = <String, Object?>{
      'payload': codec.encode(snapshot.data),
      'savedAt': snapshot.savedAt.toIso8601String(),
      'expiresAt': snapshot.expiresAt?.toIso8601String(),
      'lastSyncAt': snapshot.lastSyncAt?.toIso8601String(),
      'metadata': snapshot.metadata,
    };
    await file.writeAsString(jsonEncode(map));
  }

  @override
  Future<void> delete(RepoSnapshotKey key) async {
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
  String get logTag => 'FileRepoStatePersistenceService';
}
