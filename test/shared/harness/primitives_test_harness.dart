import 'package:grumpy/grumpy.dart';

class StringCodec implements SerializationCodec<String, String> {
  const StringCodec();

  @override
  String decode(String payload) => payload;

  @override
  String encode(String value) => value;
}

class TestKey<T> implements CacheKey<T> {
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
  String asStorageKey() => '$namespace|$schemaId|$primaryKey';
}
