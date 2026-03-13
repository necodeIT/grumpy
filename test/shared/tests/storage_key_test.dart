import 'package:grumpy/grumpy.dart';
import 'package:test/test.dart';

void main() {
  group('StorageKey', () {
    test('.asStorageKey() is reversible', () {
      final key = const StorageKey(
        namespace: 'test',
        primaryKey:
            'https://prod.liveshare.vsengsaas.visualstudio.com/join?A69716917178959CCA5C6FE98D90DD6E0F3Ahttps://prod.liveshare.vsengsaas.visualstudio.com/join?A69716917178959CCA5C6FE98D90DD6E0F3AasStorageKey()',
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
