import 'dart:io';

import 'package:grumpy/grumpy.dart';
import 'package:grumpy/src/persistence/infra/services/file_repo_state_persistence_service.dart';
import 'package:test/test.dart';
import '../harness/repo_persistence_test_harness.dart';

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
      codec: const StringCodec(),
    );

    final loaded = await service.load<String, String>(
      key,
      codec: const StringCodec(),
    );

    expect(loaded, isNotNull);
    expect(loaded!.data, 'hello');

    await dir.delete(recursive: true);
  });
}
