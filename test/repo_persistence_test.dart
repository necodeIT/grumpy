import 'dart:io';

import 'package:grumpy/grumpy.dart';
import 'package:grumpy/src/infra/services/file_repo_state_persistence_service.dart';
import 'package:test/test.dart';

void main() {
  test('file repo persistence save/load roundtrip', () async {
    final dir = await Directory.systemTemp.createTemp('grumpy_repo_test_');
    final service = FileRepoStatePersistenceService(baseDir: dir);
    const key = RepoSnapshotKey(
      namespace: 'repo',
      primaryKey: 'users',
      schemaId: 'v1',
    );

    await service.save<String, String>(
      key,
      RepoSnapshot<String>(data: 'hello', savedAt: DateTime.now()),
      codec: const _StringCodec(),
    );

    final loaded = await service.load<String, String>(
      key,
      codec: const _StringCodec(),
    );

    expect(loaded, isNotNull);
    expect(loaded!.data, 'hello');

    await dir.delete(recursive: true);
  });
}

class _StringCodec implements SerializationCodec<String, String> {
  const _StringCodec();

  @override
  String decode(String payload) => payload;

  @override
  String encode(String value) => value;
}
