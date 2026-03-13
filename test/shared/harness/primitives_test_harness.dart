import 'package:grumpy/grumpy.dart';

class StringCodec implements SerializationCodec<String, String> {
  const StringCodec();

  @override
  String decode(String payload) => payload;

  @override
  String encode(String value) => value;
}

class TestKey<T> implements StorageKey {
  const TestKey(
    this.namespace,
    this.primaryKey, {
    this.schemaId = 's1',
    this.compatVersion,
  });

  @override
  final String namespace;

  @override
  final String primaryKey;

  @override
  final String schemaId;

  @override
  final int? compatVersion;

  @override
  $StorageKeyCopyWith<StorageKey> get copyWith => StorageKey(
    namespace: namespace,
    primaryKey: primaryKey,
    schemaId: schemaId,
    compatVersion: compatVersion,
  ).copyWith;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'namespace': namespace,
    'primaryKey': primaryKey,
    'schemaId': schemaId,
    'compatVersion': compatVersion,
  };

  @override
  String asStorageKey() {
    return StorageKey(
      namespace: namespace,
      primaryKey: primaryKey,
      schemaId: schemaId,
      compatVersion: compatVersion,
    ).asStorageKey();
  }
}
