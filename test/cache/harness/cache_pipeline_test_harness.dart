import 'package:grumpy/grumpy.dart';

class TestKey<T> implements CacheKey<T> {
  const TestKey(this.namespace, this.primaryKey);

  @override
  final String namespace;

  @override
  final String primaryKey;

  @override
  String get schemaId => 's1';

  @override
  int? get compatVersion => null;

  @override
  String asStorageKey() => '$namespace|$schemaId|$primaryKey';
}
