import 'package:grumpy/grumpy.dart';

class MemoryLayer extends MemoryCacheLayerService {
  MemoryLayer() : super.internal();

  CacheEntry<Object?>? readResult;
  Object? readError;
  Object? writeError;
  int readCalls = 0;
  int writeCalls = 0;
  CacheEntry<Object?>? lastWrittenEntry;
  final List<String> invalidatedKeys = <String>[];
  final List<String> clearedNamespaces = <String>[];

  @override
  Future<CacheEntry<T>?> read<T, Serialized extends Object>(
    CacheKey<T> key, {
    SerializationCodec<T, Serialized>? codec,
  }) async {
    readCalls++;
    if (readError != null) throw readError!;
    return readResult as CacheEntry<T>?;
  }

  @override
  Future<void> write<T, Serialized extends Object>(
    CacheKey<T> key,
    CacheEntry<T> entry, {
    SerializationCodec<T, Serialized>? codec,
  }) async {
    writeCalls++;
    if (writeError != null) throw writeError!;
    lastWrittenEntry = entry as CacheEntry<Object?>;
  }

  @override
  Future<void> invalidate<T>(CacheKey<T> key) async {
    invalidatedKeys.add(key.asStorageKey());
  }

  @override
  Future<void> clearNamespace(String namespace) async {
    clearedNamespaces.add(namespace);
  }

  @override
  Future<void> free() async {}

  @override
  String get logTag => 'MemoryLayer';
}

class FileLayer extends FileCacheLayerService {
  FileLayer() : super.internal();

  CacheEntry<Object?>? readResult;
  Object? readError;
  Object? writeError;
  int readCalls = 0;
  int writeCalls = 0;
  CacheEntry<Object?>? lastWrittenEntry;
  final List<String> invalidatedKeys = <String>[];
  final List<String> clearedNamespaces = <String>[];

  @override
  Future<CacheEntry<T>?> read<T, Serialized extends Object>(
    CacheKey<T> key, {
    SerializationCodec<T, Serialized>? codec,
  }) async {
    readCalls++;
    if (readError != null) throw readError!;
    return readResult as CacheEntry<T>?;
  }

  @override
  Future<void> write<T, Serialized extends Object>(
    CacheKey<T> key,
    CacheEntry<T> entry, {
    SerializationCodec<T, Serialized>? codec,
  }) async {
    writeCalls++;
    if (writeError != null) throw writeError!;
    lastWrittenEntry = entry as CacheEntry<Object?>;
  }

  @override
  Future<void> invalidate<T>(CacheKey<T> key) async {
    invalidatedKeys.add(key.asStorageKey());
  }

  @override
  Future<void> clearNamespace(String namespace) async {
    clearedNamespaces.add(namespace);
  }

  @override
  Future<void> free() async {}

  @override
  String get logTag => 'FileLayer';
}

class TestKey<T> implements CacheKey<T> {
  const TestKey(this.namespace, this.primaryKey);

  @override
  final String namespace;

  @override
  final String primaryKey;

  @override
  String get schemaId => 'cache-schema-v1';

  @override
  int? get compatVersion => null;

  @override
  String asStorageKey() => '$namespace|$schemaId|$primaryKey';
}
