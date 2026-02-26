import 'package:grumpy/grumpy.dart';
import 'package:test/test.dart';

void main() {
  group('StorageKey', () {
    test('.asStorageKey() is reversible', () {
      final key = const StorageKey(
        namespace: 'test',
        primaryKey: 'asStorageKey()',
        schemaId: 'reversible',
      );

      final storageKey = key.asStorageKey();
      final reversedKey = StorageKey.parse(storageKey);
      expect(reversedKey, key);
      expect(storageKey, key.asStorageKey());
    });

    test('parse throws on invalid format', () {
      expect(
        () => StorageKey.parse('invalid-format'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
