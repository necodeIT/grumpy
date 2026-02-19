import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:grumpy/grumpy.dart';
import 'package:grumpy/src/transactions/infra/services/default_tx_engine_factory_service.dart';
import 'package:test/test.dart';
import '../../shared/harness/harness.dart';
import '../harness/harness.dart';

void main() {
  group('Map transaction operations', () {
    group('Operation contracts', () {
      group('MapPutEntryTxOperation', () {
        test('exposes metadata and touchedKeys', () {
          final operation = MapPutEntryTxOperation<String, int, int>(
            name: 'put',
            id: 'tx-put',
            baseVersion: 3,
            key: 'a',
            optimisticValue: 2,
            putEntry: () async => 10,
            apply: (key, optimisticValue, result) => MapEntry(key, result),
          );

          expect(operation.name, 'put');
          expect(operation.id, 'tx-put');
          expect(operation.baseVersion, 3);
          expect(operation.touchedKeys, {'a'});
        });

        test('optimisticApply puts entry without mutating input', () {
          final operation = MapPutEntryTxOperation<String, int, int>(
            name: 'put',
            id: 'tx-put',
            baseVersion: 0,
            key: 'b',
            optimisticValue: 2,
            putEntry: () async => 10,
            apply: (key, optimisticValue, result) => MapEntry(key, result),
          );
          final current = <String, int>{'a': 1};
          final optimistic = operation.optimisticApply(current);

          expect(current, {'a': 1});
          expect(optimistic, {'a': 1, 'b': 2});
          expect(identical(optimistic, current), isFalse);
        });

        test('commit delegates to putEntry exactly once', () async {
          var calls = 0;
          final operation = MapPutEntryTxOperation<String, int, int>(
            name: 'put',
            id: 'tx-put',
            baseVersion: 0,
            key: 'a',
            optimisticValue: 2,
            putEntry: () async {
              calls++;
              return 10;
            },
            apply: (key, optimisticValue, result) => MapEntry(key, result),
          );

          await expectLater(operation.commit({'a': 1}), completion(10));
          expect(calls, 1);
        });

        test(
          'applyConfirmed applies returned entry without mutating input',
          () {
            final operation = MapPutEntryTxOperation<String, int, int>(
              name: 'put',
              id: 'tx-put',
              baseVersion: 0,
              key: 'a',
              optimisticValue: 2,
              putEntry: () async => 10,
              apply: (key, optimisticValue, result) =>
                  MapEntry('$key-server', optimisticValue + result),
            );
            final confirmed = <String, int>{'a': 1};
            final settled = operation.applyConfirmed(confirmed, 10);

            expect(confirmed, {'a': 1});
            expect(settled, {'a': 1, 'a-server': 12});
            expect(identical(settled, confirmed), isFalse);
          },
        );

        test('shouldRollback defaults to true', () {
          final operation = MapPutEntryTxOperation<String, int, int>(
            name: 'put',
            id: 'tx-put',
            baseVersion: 0,
            key: 'a',
            optimisticValue: 2,
            putEntry: () async => 10,
            apply: (key, optimisticValue, result) => MapEntry(key, result),
          );

          expect(operation.shouldRollback(StateError('x'), null), isTrue);
        });

        test('shouldRollback forwards error and stackTrace to callback', () {
          Object? capturedError;
          StackTrace? capturedStackTrace;
          final operation = MapPutEntryTxOperation<String, int, int>(
            name: 'put',
            id: 'tx-put',
            baseVersion: 0,
            key: 'a',
            optimisticValue: 2,
            putEntry: () async => 10,
            apply: (key, optimisticValue, result) => MapEntry(key, result),
            shouldRollbackOnError: (error, stackTrace) {
              capturedError = error;
              capturedStackTrace = stackTrace;
              return false;
            },
          );
          final stackTrace = StackTrace.current;
          final error = StateError('x');

          expect(operation.shouldRollback(error, stackTrace), isFalse);
          expect(identical(capturedError, error), isTrue);
          expect(identical(capturedStackTrace, stackTrace), isTrue);
        });
      });

      group('MapRemoveEntryTxOperation', () {
        test('exposes metadata and touchedKeys', () {
          final operation = MapRemoveEntryTxOperation<String, int, int>(
            name: 'remove',
            id: 'tx-remove',
            baseVersion: 4,
            key: 'a',
            removeEntry: () async => 10,
            apply: (key, result) => MapEntry(key, result),
          );

          expect(operation.name, 'remove');
          expect(operation.id, 'tx-remove');
          expect(operation.baseVersion, 4);
          expect(operation.touchedKeys, {'a'});
        });

        test('optimisticApply removes key without mutating input', () {
          final operation = MapRemoveEntryTxOperation<String, int, int>(
            name: 'remove',
            id: 'tx-remove',
            baseVersion: 0,
            key: 'a',
            removeEntry: () async => 10,
            apply: (key, result) => MapEntry(key, result),
          );
          final current = <String, int>{'a': 1, 'b': 2};
          final optimistic = operation.optimisticApply(current);

          expect(current, {'a': 1, 'b': 2});
          expect(optimistic, {'b': 2});
          expect(identical(optimistic, current), isFalse);
        });

        test('optimisticApply is a no-op when key is missing', () {
          final operation = MapRemoveEntryTxOperation<String, int, int>(
            name: 'remove',
            id: 'tx-remove',
            baseVersion: 0,
            key: 'missing',
            removeEntry: () async => 10,
            apply: (key, result) => MapEntry(key, result),
          );
          final current = <String, int>{'a': 1};
          final optimistic = operation.optimisticApply(current);

          expect(current, {'a': 1});
          expect(optimistic, {'a': 1});
          expect(identical(optimistic, current), isFalse);
        });

        test('commit delegates to removeEntry exactly once', () async {
          var calls = 0;
          final operation = MapRemoveEntryTxOperation<String, int, int>(
            name: 'remove',
            id: 'tx-remove',
            baseVersion: 0,
            key: 'a',
            removeEntry: () async {
              calls++;
              return 10;
            },
            apply: (key, result) => MapEntry(key, result),
          );

          await expectLater(operation.commit({'a': 1}), completion(10));
          expect(calls, 1);
        });

        test(
          'applyConfirmed removes applied entry key without mutating input',
          () {
            final operation = MapRemoveEntryTxOperation<String, int, int>(
              name: 'remove',
              id: 'tx-remove',
              baseVersion: 0,
              key: 'a',
              removeEntry: () async => 10,
              apply: (key, result) => MapEntry('server-$key', result),
            );
            final confirmed = <String, int>{'a': 1, 'server-a': 10, 'b': 2};
            final settled = operation.applyConfirmed(confirmed, 10);

            expect(confirmed, {'a': 1, 'server-a': 10, 'b': 2});
            expect(settled, {'a': 1, 'b': 2});
            expect(identical(settled, confirmed), isFalse);
          },
        );

        test('shouldRollback defaults to true', () {
          final operation = MapRemoveEntryTxOperation<String, int, int>(
            name: 'remove',
            id: 'tx-remove',
            baseVersion: 0,
            key: 'a',
            removeEntry: () async => 10,
            apply: (key, result) => MapEntry(key, result),
          );

          expect(operation.shouldRollback(StateError('x'), null), isTrue);
        });

        test('shouldRollback forwards error and stackTrace to callback', () {
          Object? capturedError;
          StackTrace? capturedStackTrace;
          final operation = MapRemoveEntryTxOperation<String, int, int>(
            name: 'remove',
            id: 'tx-remove',
            baseVersion: 0,
            key: 'a',
            removeEntry: () async => 10,
            apply: (key, result) => MapEntry(key, result),
            shouldRollbackOnError: (error, stackTrace) {
              capturedError = error;
              capturedStackTrace = stackTrace;
              return false;
            },
          );
          final stackTrace = StackTrace.current;
          final error = StateError('x');

          expect(operation.shouldRollback(error, stackTrace), isFalse);
          expect(identical(capturedError, error), isTrue);
          expect(identical(capturedStackTrace, stackTrace), isTrue);
        });
      });

      group('MapUpdateEntryTxOperation', () {
        test('exposes metadata and touchedKeys', () {
          final operation = MapUpdateEntryTxOperation<String, Profile, String>(
            name: 'update',
            id: 'tx-update',
            baseVersion: 2,
            key: 'u1',
            touchedValueKeys: const {'name', 'status'},
            optimisticUpdate: (entry) =>
                entry.value.copyWith(name: '${entry.value.name}!'),
            updateEntry: (entry) async => 'server',
            apply: (optimisticEntry, result) => MapEntry(
              optimisticEntry.key,
              optimisticEntry.value.copyWith(name: result),
            ),
          );

          expect(operation.name, 'update');
          expect(operation.id, 'tx-update');
          expect(operation.baseVersion, 2);
          expect(operation.touchedKeys, {'u1.name', 'u1.status'});
        });

        test(
          'optimisticApply updates only targeted key without mutating input',
          () {
            final operation =
                MapUpdateEntryTxOperation<String, Profile, String>(
                  name: 'update',
                  id: 'tx-update',
                  baseVersion: 0,
                  key: 'u1',
                  touchedValueKeys: const {'name'},
                  optimisticUpdate: (entry) =>
                      entry.value.copyWith(name: '${entry.value.name}*'),
                  updateEntry: (entry) async => 'server',
                  apply: (optimisticEntry, result) => MapEntry(
                    optimisticEntry.key,
                    optimisticEntry.value.copyWith(name: result),
                  ),
                );
            final current = <String, Profile>{
              'u1': const Profile(name: 'Alice', status: 'active'),
              'u2': const Profile(name: 'Bob', status: 'active'),
            };
            final optimistic = operation.optimisticApply(current);

            expect(
              current['u1'],
              const Profile(name: 'Alice', status: 'active'),
            );
            expect(
              optimistic['u1'],
              const Profile(name: 'Alice*', status: 'active'),
            );
            expect(
              optimistic['u2'],
              const Profile(name: 'Bob', status: 'active'),
            );
            expect(identical(optimistic, current), isFalse);
          },
        );

        test(
          'commit delegates to updateEntry with targeted current entry',
          () async {
            MapEntry<String, Profile>? committedEntry;
            final operation =
                MapUpdateEntryTxOperation<String, Profile, String>(
                  name: 'update',
                  id: 'tx-update',
                  baseVersion: 0,
                  key: 'u1',
                  touchedValueKeys: const {'name'},
                  optimisticUpdate: (entry) =>
                      entry.value.copyWith(name: '${entry.value.name}*'),
                  updateEntry: (entry) async {
                    committedEntry = entry;
                    return 'server';
                  },
                  apply: (optimisticEntry, result) => MapEntry(
                    optimisticEntry.key,
                    optimisticEntry.value.copyWith(name: result),
                  ),
                );

            await expectLater(
              operation.commit({
                'u1': const Profile(name: 'Alice', status: 'active'),
              }),
              completion('server'),
            );

            expect(committedEntry?.key, 'u1');
            expect(
              committedEntry?.value,
              const Profile(name: 'Alice', status: 'active'),
            );
          },
        );

        test(
          'applyConfirmed applies returned entry without mutating input',
          () {
            final operation =
                MapUpdateEntryTxOperation<String, Profile, String>(
                  name: 'update',
                  id: 'tx-update',
                  baseVersion: 0,
                  key: 'u1',
                  touchedValueKeys: const {'name'},
                  optimisticUpdate: (entry) =>
                      entry.value.copyWith(name: '${entry.value.name}!'),
                  updateEntry: (entry) async => 'server',
                  apply: (optimisticEntry, result) => MapEntry(
                    optimisticEntry.key,
                    optimisticEntry.value.copyWith(name: result),
                  ),
                );
            final confirmed = <String, Profile>{
              'u1': const Profile(name: 'Alice', status: 'active'),
            };
            final settled = operation.applyConfirmed(confirmed, 'server');

            expect(
              confirmed['u1'],
              const Profile(name: 'Alice', status: 'active'),
            );
            expect(
              settled?['u1'],
              const Profile(name: 'server', status: 'active'),
            );
            expect(identical(settled, confirmed), isFalse);
          },
        );

        test('applyConfirmed returns null when key is missing', () {
          final operation = MapUpdateEntryTxOperation<String, Profile, String>(
            name: 'update',
            id: 'tx-update',
            baseVersion: 0,
            key: 'missing',
            touchedValueKeys: const {'name'},
            optimisticUpdate: (entry) =>
                entry.value.copyWith(name: '${entry.value.name}!'),
            updateEntry: (entry) async => 'server',
            apply: (optimisticEntry, result) => MapEntry(
              optimisticEntry.key,
              optimisticEntry.value.copyWith(name: result),
            ),
          );

          expect(
            operation.applyConfirmed({
              'u1': const Profile(name: 'Alice', status: 'active'),
            }, 'server'),
            isNull,
          );
        });

        test('shouldRollback defaults to true', () {
          final operation = MapUpdateEntryTxOperation<String, Profile, String>(
            name: 'update',
            id: 'tx-update',
            baseVersion: 0,
            key: 'u1',
            touchedValueKeys: const {'name'},
            optimisticUpdate: (entry) =>
                entry.value.copyWith(name: '${entry.value.name}!'),
            updateEntry: (entry) async => 'server',
            apply: (optimisticEntry, result) => MapEntry(
              optimisticEntry.key,
              optimisticEntry.value.copyWith(name: result),
            ),
          );

          expect(operation.shouldRollback(StateError('x'), null), isTrue);
        });
      });

      group('MapChangeKeyTxOperation', () {
        test('exposes metadata and touchedKeys', () {
          final operation = MapChangeKeyTxOperation<String, int, String>(
            name: 'change-key',
            id: 'tx-change-key',
            baseVersion: 1,
            oldKey: 'old',
            newKey: 'new',
            conflictResolution: MapChangeKeyConflictResolution.overwrite,
            changeKey: (oldKey, newKey, value) async => 'server',
            apply: (oldKey, newKey, value, result) => newKey,
          );

          expect(operation.name, 'change-key');
          expect(operation.id, 'tx-change-key');
          expect(operation.baseVersion, 1);
          expect(operation.touchedKeys, {'old', 'new'});
        });

        test('optimisticApply migrates value without mutating input', () {
          final operation = MapChangeKeyTxOperation<String, int, String>(
            name: 'change-key',
            id: 'tx-change-key',
            baseVersion: 0,
            oldKey: 'old',
            newKey: 'new',
            conflictResolution: MapChangeKeyConflictResolution.overwrite,
            changeKey: (oldKey, newKey, value) async => 'server',
            apply: (oldKey, newKey, value, result) => newKey,
          );
          final current = <String, int>{'old': 1, 'other': 2};
          final optimistic = operation.optimisticApply(current);

          expect(current, {'old': 1, 'other': 2});
          expect(optimistic, {'new': 1, 'other': 2});
          expect(identical(optimistic, current), isFalse);
        });

        test(
          'optimisticApply returns current instance when old key is missing',
          () {
            final operation = MapChangeKeyTxOperation<String, int, String>(
              name: 'change-key',
              id: 'tx-change-key',
              baseVersion: 0,
              oldKey: 'old',
              newKey: 'new',
              conflictResolution: MapChangeKeyConflictResolution.overwrite,
              changeKey: (oldKey, newKey, value) async => 'server',
              apply: (oldKey, newKey, value, result) => newKey,
            );
            final current = <String, int>{'other': 2};
            final optimistic = operation.optimisticApply(current);

            expect(optimistic, current);
            expect(identical(optimistic, current), isTrue);
          },
        );

        test(
          'commit delegates to changeKey with old/new key and value',
          () async {
            String? capturedOld;
            String? capturedNew;
            int? capturedValue;
            final operation = MapChangeKeyTxOperation<String, int, String>(
              name: 'change-key',
              id: 'tx-change-key',
              baseVersion: 0,
              oldKey: 'old',
              newKey: 'new',
              conflictResolution: MapChangeKeyConflictResolution.overwrite,
              changeKey: (oldKey, newKey, value) async {
                capturedOld = oldKey;
                capturedNew = newKey;
                capturedValue = value;
                return 'server';
              },
              apply: (oldKey, newKey, value, result) => newKey,
            );

            await expectLater(
              operation.commit({'old': 7}),
              completion('server'),
            );
            expect(capturedOld, 'old');
            expect(capturedNew, 'new');
            expect(capturedValue, 7);
          },
        );

        test('commit throws when old key is missing', () async {
          final operation = MapChangeKeyTxOperation<String, int, String>(
            name: 'change-key',
            id: 'tx-change-key',
            baseVersion: 0,
            oldKey: 'old',
            newKey: 'new',
            conflictResolution: MapChangeKeyConflictResolution.overwrite,
            changeKey: (oldKey, newKey, value) async => 'server',
            apply: (oldKey, newKey, value, result) => newKey,
          );

          await expectLater(
            () => operation.commit({'other': 1}),
            throwsA(isA<StateError>()),
          );
        });

        test('applyConfirmed applies returned key when old key exists', () {
          final operation = MapChangeKeyTxOperation<String, int, String>(
            name: 'change-key',
            id: 'tx-change-key',
            baseVersion: 0,
            oldKey: 'old',
            newKey: 'new',
            conflictResolution: MapChangeKeyConflictResolution.overwrite,
            changeKey: (oldKey, newKey, value) async => 'server',
            apply: (oldKey, newKey, value, result) => '$newKey-confirmed',
          );
          final confirmed = <String, int>{'old': 1, 'other': 2};
          final settled = operation.applyConfirmed(confirmed, 'server');

          expect(confirmed, {'old': 1, 'other': 2});
          expect(settled, {'new-confirmed': 1, 'other': 2});
          expect(identical(settled, confirmed), isFalse);
        });

        test('applyConfirmed returns null when old key is missing', () {
          final operation = MapChangeKeyTxOperation<String, int, String>(
            name: 'change-key',
            id: 'tx-change-key',
            baseVersion: 0,
            oldKey: 'old',
            newKey: 'new',
            conflictResolution: MapChangeKeyConflictResolution.overwrite,
            changeKey: (oldKey, newKey, value) async => 'server',
            apply: (oldKey, newKey, value, result) => newKey,
          );

          expect(operation.applyConfirmed({'other': 1}, 'server'), isNull);
        });

        test(
          'applyConfirmed returns null when new key exists and strategy is rollback',
          () {
            final operation = MapChangeKeyTxOperation<String, int, String>(
              name: 'change-key',
              id: 'tx-change-key',
              baseVersion: 0,
              oldKey: 'old',
              newKey: 'new',
              conflictResolution: MapChangeKeyConflictResolution.rollback,
              changeKey: (oldKey, newKey, value) async => 'server',
              apply: (oldKey, newKey, value, result) => newKey,
            );

            expect(
              operation.applyConfirmed({'old': 1, 'new': 2}, 'server'),
              isNull,
            );
          },
        );

        test(
          'applyConfirmed overwrites existing new key when strategy is overwrite',
          () {
            final operation = MapChangeKeyTxOperation<String, int, String>(
              name: 'change-key',
              id: 'tx-change-key',
              baseVersion: 0,
              oldKey: 'old',
              newKey: 'new',
              conflictResolution: MapChangeKeyConflictResolution.overwrite,
              changeKey: (oldKey, newKey, value) async => 'server',
              apply: (oldKey, newKey, value, result) => newKey,
            );

            expect(
              operation.applyConfirmed({
                'old': 1,
                'new': 2,
                'other': 3,
              }, 'server'),
              {'new': 1, 'other': 3},
            );
          },
        );

        test('shouldRollback defaults to true', () {
          final operation = MapChangeKeyTxOperation<String, int, String>(
            name: 'change-key',
            id: 'tx-change-key',
            baseVersion: 0,
            oldKey: 'old',
            newKey: 'new',
            conflictResolution: MapChangeKeyConflictResolution.overwrite,
            changeKey: (oldKey, newKey, value) async => 'server',
            apply: (oldKey, newKey, value, result) => newKey,
          );

          expect(operation.shouldRollback(StateError('x'), null), isTrue);
        });

        test('shouldRollback forwards error and stackTrace to callback', () {
          Object? capturedError;
          StackTrace? capturedStackTrace;
          final operation = MapChangeKeyTxOperation<String, int, String>(
            name: 'change-key',
            id: 'tx-change-key',
            baseVersion: 0,
            oldKey: 'old',
            newKey: 'new',
            conflictResolution: MapChangeKeyConflictResolution.overwrite,
            changeKey: (oldKey, newKey, value) async => 'server',
            apply: (oldKey, newKey, value, result) => newKey,
            shouldRollbackOnError: (error, stackTrace) {
              capturedError = error;
              capturedStackTrace = stackTrace;
              return false;
            },
          );
          final stackTrace = StackTrace.current;
          final error = StateError('x');

          expect(operation.shouldRollback(error, stackTrace), isFalse);
          expect(identical(capturedError, error), isTrue);
          expect(identical(capturedStackTrace, stackTrace), isTrue);
        });
      });
    });

    group('Integration', () {
      final di = GetIt.instance;
      late RecordingTelemetryService telemetry;
      late RecordingAnalyticsService analytics;

      setUp(() async {
        await di.reset();
        telemetry = RecordingTelemetryService();
        analytics = RecordingAnalyticsService();
        di.registerSingleton<TelemetryService>(telemetry);
        di.registerSingleton<AnalyticsService>(analytics);
        di.registerSingleton<TxEngineFactoryService>(
          DefaultTxEngineFactoryService(),
        );
      });

      tearDown(() async {
        await di.reset();
      });

      group('TxEngine usage', () {
        test(
          'applies put operation from enqueue through successful settlement',
          () async {
            final engine = TxEngine<Map<String, Profile>>({
              'u1': const Profile(name: 'Alice', status: 'active'),
            });
            final operation = MapPutEntryTxOperation<String, Profile, String>(
              name: 'put',
              id: 'tx-put',
              baseVersion: 0,
              key: 'u2',
              optimisticValue: const Profile(name: 'Temp', status: 'pending'),
              putEntry: () async => 'server',
              apply: (key, optimisticValue, result) =>
                  MapEntry(key, const Profile(name: 'Bob', status: 'active')),
            );

            engine.enqueue(
              id: operation.id,
              touchedKeys: operation.touchedKeys,
              apply: operation.optimisticApply,
            );

            expect(engine.computeVisible(), {
              'u1': const Profile(name: 'Alice', status: 'active'),
              'u2': const Profile(name: 'Temp', status: 'pending'),
            });
            expect(engine.pending.map((p) => p.id), [operation.id]);

            final commitResult = await operation.commit(engine.confirmed);
            engine.settleSuccess(
              operation.id,
              commitResult,
              operation.applyConfirmed,
            );

            expect(engine.confirmed, {
              'u1': const Profile(name: 'Alice', status: 'active'),
              'u2': const Profile(name: 'Bob', status: 'active'),
            });
            expect(engine.computeVisible(), {
              'u1': const Profile(name: 'Alice', status: 'active'),
              'u2': const Profile(name: 'Bob', status: 'active'),
            });
            expect(engine.confirmedVersion, 1);
            expect(engine.pending, isEmpty);
          },
        );

        test('removes failed optimistic remove operation on settleFailure', () {
          final engine = TxEngine<Map<String, Profile>>({
            'u1': const Profile(name: 'Alice', status: 'active'),
            'u2': const Profile(name: 'Bob', status: 'active'),
          });
          final operation = MapRemoveEntryTxOperation<String, Profile, String>(
            name: 'remove',
            id: 'tx-remove',
            baseVersion: 0,
            key: 'u2',
            removeEntry: () async => 'server',
            apply: (key, result) =>
                MapEntry(key, const Profile(name: 'Bob', status: 'active')),
          );

          engine.enqueue(
            id: operation.id,
            touchedKeys: operation.touchedKeys,
            apply: operation.optimisticApply,
          );

          expect(engine.computeVisible(), {
            'u1': const Profile(name: 'Alice', status: 'active'),
          });

          engine.settleFailure(operation.id);

          expect(engine.computeVisible(), {
            'u1': const Profile(name: 'Alice', status: 'active'),
            'u2': const Profile(name: 'Bob', status: 'active'),
          });
          expect(engine.confirmed, {
            'u1': const Profile(name: 'Alice', status: 'active'),
            'u2': const Profile(name: 'Bob', status: 'active'),
          });
          expect(engine.pending, isEmpty);
        });

        test(
          'keeps newer overlapping update authoritative after older settles',
          () async {
            final seed = {'u1': const Profile(name: 'Alice', status: 'active')};
            final engine = TxEngine<Map<String, Profile>>(seed);
            final older = MapUpdateEntryTxOperation<String, Profile, String>(
              name: 'older',
              id: 'tx-older',
              baseVersion: 0,
              key: 'u1',
              touchedValueKeys: const {'name'},
              optimisticUpdate: (entry) =>
                  entry.value.copyWith(name: 'Alice-older'),
              updateEntry: (entry) async => 'server-older',
              apply: (optimisticEntry, result) => MapEntry(
                optimisticEntry.key,
                optimisticEntry.value.copyWith(name: result),
              ),
            );
            final newer = MapUpdateEntryTxOperation<String, Profile, String>(
              name: 'newer',
              id: 'tx-newer',
              baseVersion: 0,
              key: 'u1',
              touchedValueKeys: const {'name'},
              optimisticUpdate: (entry) =>
                  entry.value.copyWith(name: 'Alice-newer'),
              updateEntry: (entry) async => 'server-newer',
              apply: (optimisticEntry, result) => MapEntry(
                optimisticEntry.key,
                optimisticEntry.value.copyWith(name: result),
              ),
            );

            engine.enqueue(
              id: older.id,
              touchedKeys: older.touchedKeys,
              apply: older.optimisticApply,
            );
            engine.enqueue(
              id: newer.id,
              touchedKeys: newer.touchedKeys,
              apply: newer.optimisticApply,
            );

            expect(engine.computeVisible(), {
              'u1': const Profile(name: 'Alice-newer', status: 'active'),
            });

            final newerResult = await newer.commit(engine.confirmed);
            engine.settleSuccess(newer.id, newerResult, newer.applyConfirmed);
            expect(engine.confirmed, {
              'u1': const Profile(name: 'server-newer', status: 'active'),
            });

            final olderResult = await older.commit(engine.confirmed);
            engine.settleSuccess(older.id, olderResult, older.applyConfirmed);

            expect(engine.confirmed, {
              'u1': const Profile(name: 'server-newer', status: 'active'),
            });
            expect(engine.computeVisible(), {
              'u1': const Profile(name: 'server-newer', status: 'active'),
            });
            expect(engine.confirmedVersion, 1);
          },
        );
      });

      group('TransactionalMutationMixin usage', () {
        late MapProfileTxRepo repo;

        setUp(() {
          repo = MapProfileTxRepo();
        });

        tearDown(() async {
          await repo.free();
        });

        test(
          'applies optimistic put immediately and settles to confirmed put',
          () async {
            repo.data({'u1': const Profile(name: 'Alice', status: 'active')});
            final commit = Completer<String>();
            final operation = MapPutEntryTxOperation<String, Profile, String>(
              name: 'put-profile',
              id: repo.nextTxId(),
              baseVersion: 0,
              key: 'u2',
              optimisticValue: const Profile(name: 'Temp', status: 'pending'),
              putEntry: () => commit.future,
              apply: (key, optimisticValue, result) =>
                  MapEntry(key, const Profile(name: 'Bob', status: 'active')),
            );

            final future = repo.transact<String>(
              operation,
              analyticsAttributes: const {'source': 'test'},
            );

            await Future<void>.delayed(Duration.zero);
            expect(repo.state.requireData, {
              'u1': const Profile(name: 'Alice', status: 'active'),
              'u2': const Profile(name: 'Temp', status: 'pending'),
            });
            expect(analytics.events, contains('mutation_put-profile'));
            expect(
              telemetry.runSpanNames,
              containsAll(['put-profile', 'try_0']),
            );

            commit.complete('server');
            final result = await future;

            expect(result.success, isTrue);
            expect(result.value, 'server');
            expect(result.visibleState, {
              'u1': const Profile(name: 'Alice', status: 'active'),
              'u2': const Profile(name: 'Bob', status: 'active'),
            });
            expect(repo.state.requireData, {
              'u1': const Profile(name: 'Alice', status: 'active'),
              'u2': const Profile(name: 'Bob', status: 'active'),
            });
            expect(
              analytics.eventProperties['mutation_put-profile']?['source'],
              'test',
            );
          },
        );

        test('rolls back optimistic remove when commit fails', () async {
          repo.data({
            'u1': const Profile(name: 'Alice', status: 'active'),
            'u2': const Profile(name: 'Bob', status: 'active'),
          });
          final commit = Completer<String>();
          final operation = MapRemoveEntryTxOperation<String, Profile, String>(
            name: 'remove-profile',
            id: repo.nextTxId(),
            baseVersion: 0,
            key: 'u2',
            removeEntry: () => commit.future,
            apply: (key, result) =>
                MapEntry(key, const Profile(name: 'Bob', status: 'active')),
          );

          final future = repo.transact<String>(operation);

          await Future<void>.delayed(Duration.zero);
          expect(repo.state.requireData, {
            'u1': const Profile(name: 'Alice', status: 'active'),
          });

          commit.completeError(StateError('network'));
          final result = await future;

          expect(result.success, isFalse);
          expect(result.error, isA<StateError>());
          expect(repo.state.requireData, {
            'u1': const Profile(name: 'Alice', status: 'active'),
            'u2': const Profile(name: 'Bob', status: 'active'),
          });
        });

        test(
          'keeps newer overlapping update visible when older commit settles later',
          () async {
            repo.data({'u1': const Profile(name: 'Alice', status: 'active')});
            final olderCommit = Completer<String>();
            final newerCommit = Completer<String>();

            final older = MapUpdateEntryTxOperation<String, Profile, String>(
              name: 'edit-profile-older',
              id: repo.nextTxId(),
              baseVersion: 0,
              key: 'u1',
              touchedValueKeys: const {'name'},
              optimisticUpdate: (entry) =>
                  entry.value.copyWith(name: 'Alice-older'),
              updateEntry: (entry) => olderCommit.future,
              apply: (optimisticEntry, result) => MapEntry(
                optimisticEntry.key,
                optimisticEntry.value.copyWith(name: result),
              ),
            );
            final newer = MapUpdateEntryTxOperation<String, Profile, String>(
              name: 'edit-profile-newer',
              id: repo.nextTxId(),
              baseVersion: 0,
              key: 'u1',
              touchedValueKeys: const {'name'},
              optimisticUpdate: (entry) =>
                  entry.value.copyWith(name: 'Alice-newer'),
              updateEntry: (entry) => newerCommit.future,
              apply: (optimisticEntry, result) => MapEntry(
                optimisticEntry.key,
                optimisticEntry.value.copyWith(name: result),
              ),
            );

            final olderFuture = repo.transact<String>(older);
            final newerFuture = repo.transact<String>(newer);

            await Future<void>.delayed(Duration.zero);
            expect(repo.state.requireData, {
              'u1': const Profile(name: 'Alice-newer', status: 'active'),
            });

            newerCommit.complete('server-newer');
            final newerResult = await newerFuture;
            expect(newerResult.success, isTrue);
            expect(repo.state.requireData, {
              'u1': const Profile(name: 'Alice-older', status: 'active'),
            });

            olderCommit.complete('server-older');
            final olderResult = await olderFuture;
            expect(olderResult.success, isTrue);
            expect(repo.state.requireData, {
              'u1': const Profile(name: 'server-newer', status: 'active'),
            });
            expect(
              analytics.events,
              containsAll([
                'mutation_edit-profile-older',
                'mutation_edit-profile-newer',
              ]),
            );
          },
        );
      });
    });
  });
}
