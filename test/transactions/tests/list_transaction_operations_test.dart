import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:grumpy/grumpy.dart';
import 'package:grumpy/src/transactions/infra/services/default_tx_engine_factory_service.dart';
import 'package:test/test.dart';
import '../../shared/harness/harness.dart';

void main() {
  group('List transaction operations', () {
    group('Operation contracts', () {
      group('ListAddElementTxOperation', () {
        test('exposes metadata and touchedKeys', () {
          Future<int> createElement() async => 10;
          final operation = ListAddElementTxOperation<int, int>(
            name: 'add',
            id: 'tx-add',
            baseVersion: 3,
            element: 2,
            createElement: createElement,
            apply: (optimisticElement, result) => optimisticElement + result,
          );

          expect(operation.name, 'add');
          expect(operation.id, 'tx-add');
          expect(operation.baseVersion, 3);
          expect(operation.touchedKeys, {createElement.toString()});
        });

        test('optimisticApply appends element without mutating input', () {
          final operation = ListAddElementTxOperation<int, int>(
            name: 'add',
            id: 'tx-add',
            baseVersion: 0,
            element: 2,
            createElement: () async => 10,
            apply: (optimisticElement, result) => optimisticElement + result,
          );
          final current = <int>[1];
          final optimistic = operation.optimisticApply(current);

          expect(current, [1]);
          expect(optimistic, [1, 2]);
          expect(identical(optimistic, current), isFalse);
        });

        test('commit delegates to createElement exactly once', () async {
          var calls = 0;
          final operation = ListAddElementTxOperation<int, int>(
            name: 'add',
            id: 'tx-add',
            baseVersion: 0,
            element: 2,
            createElement: () async {
              calls++;
              return 10;
            },
            apply: (optimisticElement, result) => optimisticElement + result,
          );

          await expectLater(operation.commit([1]), completion(10));
          expect(calls, 1);
        });

        test(
          'applyConfirmed appends applied element without mutating input',
          () {
            final operation = ListAddElementTxOperation<int, int>(
              name: 'add',
              id: 'tx-add',
              baseVersion: 0,
              element: 2,
              createElement: () async => 10,
              apply: (optimisticElement, result) => optimisticElement + result,
            );
            final confirmed = <int>[1];
            final settled = operation.applyConfirmed(confirmed, 10);

            expect(confirmed, [1]);
            expect(settled, [1, 12]);
            expect(identical(settled, confirmed), isFalse);
          },
        );

        test('shouldRollback defaults to true', () {
          final operation = ListAddElementTxOperation<int, int>(
            name: 'add',
            id: 'tx-add',
            baseVersion: 0,
            element: 2,
            createElement: () async => 10,
            apply: (optimisticElement, result) => optimisticElement + result,
          );

          expect(operation.shouldRollback(StateError('x'), null), isTrue);
        });

        test('shouldRollback forwards error and stackTrace to callback', () {
          Object? capturedError;
          StackTrace? capturedStackTrace;
          final operation = ListAddElementTxOperation<int, int>(
            name: 'add',
            id: 'tx-add',
            baseVersion: 0,
            element: 2,
            createElement: () async => 10,
            apply: (optimisticElement, result) => optimisticElement + result,
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

      group('ListRemoveElementTxOperation', () {
        test('exposes metadata and touchedKeys', () {
          Future<int> removeElement() async => 10;
          final operation = ListRemoveElementTxOperation<int, int>(
            name: 'remove',
            id: 'tx-remove',
            baseVersion: 4,
            element: 2,
            removeElement: removeElement,
            apply: (optimisticElement, result) => optimisticElement,
          );

          expect(operation.name, 'remove');
          expect(operation.id, 'tx-remove');
          expect(operation.baseVersion, 4);
          expect(operation.touchedKeys, {2.toString()});
        });

        test('optimisticApply removes element without mutating input', () {
          final operation = ListRemoveElementTxOperation<int, int>(
            name: 'remove',
            id: 'tx-remove',
            baseVersion: 0,
            element: 2,
            removeElement: () async => 10,
            apply: (optimisticElement, result) => optimisticElement,
          );
          final current = <int>[1, 2, 3];
          final optimistic = operation.optimisticApply(current);

          expect(current, [1, 2, 3]);
          expect(optimistic, [1, 3]);
          expect(identical(optimistic, current), isFalse);
        });

        test('optimisticApply is a no-op when element is missing', () {
          final operation = ListRemoveElementTxOperation<int, int>(
            name: 'remove',
            id: 'tx-remove',
            baseVersion: 0,
            element: 9,
            removeElement: () async => 10,
            apply: (optimisticElement, result) => optimisticElement,
          );
          final current = <int>[1, 2, 3];
          final optimistic = operation.optimisticApply(current);

          expect(current, [1, 2, 3]);
          expect(optimistic, [1, 2, 3]);
          expect(identical(optimistic, current), isFalse);
        });

        test('commit delegates to removeElement exactly once', () async {
          var calls = 0;
          final operation = ListRemoveElementTxOperation<int, int>(
            name: 'remove',
            id: 'tx-remove',
            baseVersion: 0,
            element: 2,
            removeElement: () async {
              calls++;
              return 10;
            },
            apply: (optimisticElement, result) => optimisticElement,
          );

          await expectLater(operation.commit([1, 2, 3]), completion(10));
          expect(calls, 1);
        });

        test(
          'applyConfirmed removes applied element without mutating input',
          () {
            final operation = ListRemoveElementTxOperation<int, int>(
              name: 'remove',
              id: 'tx-remove',
              baseVersion: 0,
              element: 2,
              removeElement: () async => 10,
              apply: (optimisticElement, result) => 20,
            );
            final confirmed = <int>[1, 2, 3, 20];
            final settled = operation.applyConfirmed(confirmed, 10);

            expect(confirmed, [1, 2, 3, 20]);
            expect(settled, [1, 2, 3]);
            expect(identical(settled, confirmed), isFalse);
          },
        );

        test('shouldRollback defaults to true', () {
          final operation = ListRemoveElementTxOperation<int, int>(
            name: 'remove',
            id: 'tx-remove',
            baseVersion: 0,
            element: 2,
            removeElement: () async => 10,
            apply: (optimisticElement, result) => optimisticElement,
          );

          expect(operation.shouldRollback(StateError('x'), null), isTrue);
        });

        test('shouldRollback forwards error and stackTrace to callback', () {
          Object? capturedError;
          StackTrace? capturedStackTrace;
          final operation = ListRemoveElementTxOperation<int, int>(
            name: 'remove',
            id: 'tx-remove',
            baseVersion: 0,
            element: 2,
            removeElement: () async => 10,
            apply: (optimisticElement, result) => optimisticElement,
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

      group('ListUpdateElementTxOperation', () {
        test('exposes metadata and touchedKeys', () {
          const element = _Item(id: 1, name: 'A');
          final operation = ListUpdateElementTxOperation<_Item, String>(
            name: 'update',
            id: 'tx-update',
            baseVersion: 2,
            touchedElementKeys: const {'name', 'status'},
            element: element,
            optimisticUpdate: (current) => current.copyWith(name: 'A*'),
            updateElement: (target) async => 'server',
            apply: (optimisticElement, result) =>
                optimisticElement.copyWith(name: result),
          );

          expect(operation.name, 'update');
          expect(operation.id, 'tx-update');
          expect(operation.baseVersion, 2);
          expect(operation.touchedKeys, {'$element.name', '$element.status'});
        });

        test('optimisticApply updates only matching element', () {
          const target = _Item(id: 1, name: 'A');
          const other = _Item(id: 2, name: 'B');
          final operation = ListUpdateElementTxOperation<_Item, String>(
            name: 'update',
            id: 'tx-update',
            baseVersion: 0,
            touchedElementKeys: const {'name'},
            element: target,
            optimisticUpdate: (current) => current.copyWith(name: 'A*'),
            updateElement: (item) async => 'server',
            apply: (optimisticElement, result) =>
                optimisticElement.copyWith(name: result),
          );
          final current = <_Item>[target, other];
          final optimistic = operation.optimisticApply(current);

          expect(current, [target, other]);
          expect(optimistic, [const _Item(id: 1, name: 'A*'), other]);
          expect(identical(optimistic, current), isFalse);
        });

        test('optimisticApply is a no-op when element is missing', () {
          const target = _Item(id: 1, name: 'A');
          const other = _Item(id: 2, name: 'B');
          final operation = ListUpdateElementTxOperation<_Item, String>(
            name: 'update',
            id: 'tx-update',
            baseVersion: 0,
            touchedElementKeys: const {'name'},
            element: target,
            optimisticUpdate: (current) => current.copyWith(name: 'A*'),
            updateElement: (item) async => 'server',
            apply: (optimisticElement, result) =>
                optimisticElement.copyWith(name: result),
          );
          final current = <_Item>[other];
          final optimistic = operation.optimisticApply(current);

          expect(current, [other]);
          expect(optimistic, [other]);
        });

        test(
          'commit delegates to updateElement with configured element',
          () async {
            const configured = _Item(id: 1, name: 'A');
            _Item? committedElement;
            final operation = ListUpdateElementTxOperation<_Item, String>(
              name: 'update',
              id: 'tx-update',
              baseVersion: 0,
              touchedElementKeys: const {'name'},
              element: configured,
              optimisticUpdate: (current) => current.copyWith(name: 'A*'),
              updateElement: (item) async {
                committedElement = item;
                return 'server';
              },
              apply: (optimisticElement, result) =>
                  optimisticElement.copyWith(name: result),
            );

            await expectLater(
              operation.commit([const _Item(id: 1, name: 'DIFFERENT')]),
              completion('server'),
            );
            expect(committedElement, configured);
          },
        );

        test('applyConfirmed uses optimisticUpdate output before apply', () {
          const target = _Item(id: 1, name: 'A');
          final operation = ListUpdateElementTxOperation<_Item, String>(
            name: 'update',
            id: 'tx-update',
            baseVersion: 0,
            touchedElementKeys: const {'name'},
            element: target,
            optimisticUpdate: (current) =>
                current.copyWith(name: '${current.name}!'),
            updateElement: (item) async => 'server',
            apply: (optimisticElement, result) => optimisticElement.copyWith(
              name: '${optimisticElement.name}-$result',
            ),
          );
          final confirmed = <_Item>[target];
          final settled = operation.applyConfirmed(confirmed, 'server');

          expect(confirmed, [target]);
          expect(settled, [const _Item(id: 1, name: 'A!-server')]);
        });

        test('applyConfirmed returns null when element is missing', () {
          final operation = ListUpdateElementTxOperation<_Item, String>(
            name: 'update',
            id: 'tx-update',
            baseVersion: 0,
            touchedElementKeys: const {'name'},
            element: const _Item(id: 1, name: 'A'),
            optimisticUpdate: (current) => current.copyWith(name: 'A*'),
            updateElement: (item) async => 'server',
            apply: (optimisticElement, result) =>
                optimisticElement.copyWith(name: result),
          );

          expect(
            operation.applyConfirmed(const [_Item(id: 2, name: 'B')], 'server'),
            isNull,
          );
        });

        test('shouldRollback defaults to true', () {
          final operation = ListUpdateElementTxOperation<_Item, String>(
            name: 'update',
            id: 'tx-update',
            baseVersion: 0,
            touchedElementKeys: const {'name'},
            element: const _Item(id: 1, name: 'A'),
            optimisticUpdate: (current) => current.copyWith(name: 'A*'),
            updateElement: (item) async => 'server',
            apply: (optimisticElement, result) =>
                optimisticElement.copyWith(name: result),
          );

          expect(operation.shouldRollback(StateError('x'), null), isTrue);
        });

        test('shouldRollback forwards error and stackTrace to callback', () {
          Object? capturedError;
          StackTrace? capturedStackTrace;
          final operation = ListUpdateElementTxOperation<_Item, String>(
            name: 'update',
            id: 'tx-update',
            baseVersion: 0,
            touchedElementKeys: const {'name'},
            element: const _Item(id: 1, name: 'A'),
            optimisticUpdate: (current) => current.copyWith(name: 'A*'),
            updateElement: (item) async => 'server',
            apply: (optimisticElement, result) =>
                optimisticElement.copyWith(name: result),
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
          'applies add operation from enqueue through successful settlement',
          () async {
            final seed = [_item(id: 1, name: 'A')];
            final engine = TxEngine<List<_Item>>(seed);
            final operation = ListAddElementTxOperation<_Item, int>(
              name: 'add',
              id: 'tx-add',
              baseVersion: 0,
              element: _item(id: -1, name: 'temp'),
              createElement: () async => 2,
              apply: (optimisticElement, result) =>
                  _item(id: result, name: 'B'),
            );

            engine.enqueue(
              id: operation.id,
              touchedKeys: operation.touchedKeys,
              apply: operation.optimisticApply,
            );

            expect(engine.computeVisible(), [
              seed.first,
              _item(id: -1, name: 'temp'),
            ]);
            expect(engine.pending.map((p) => p.id), [operation.id]);

            final commitResult = await operation.commit(engine.confirmed);
            engine.settleSuccess(
              operation.id,
              commitResult,
              operation.applyConfirmed,
            );

            expect(engine.confirmed, [seed.first, _item(id: 2, name: 'B')]);
            expect(engine.computeVisible(), [
              seed.first,
              _item(id: 2, name: 'B'),
            ]);
            expect(engine.confirmedVersion, 1);
            expect(engine.pending, isEmpty);
          },
        );

        test('removes failed optimistic remove operation on settleFailure', () {
          final a = _item(id: 1, name: 'A');
          final b = _item(id: 2, name: 'B');
          final engine = TxEngine<List<_Item>>([a, b]);
          final operation = ListRemoveElementTxOperation<_Item, int>(
            name: 'remove',
            id: 'tx-remove',
            baseVersion: 0,
            element: b,
            removeElement: () async => 2,
            apply: (optimisticElement, result) => _item(id: result, name: 'B'),
          );

          engine.enqueue(
            id: operation.id,
            touchedKeys: operation.touchedKeys,
            apply: operation.optimisticApply,
          );

          expect(engine.computeVisible(), [a]);
          engine.settleFailure(operation.id);
          expect(engine.computeVisible(), [a, b]);
          expect(engine.confirmed, [a, b]);
          expect(engine.pending, isEmpty);
        });

        test(
          'keeps newer overlapping update authoritative after older settles',
          () async {
            final base = _item(id: 1, name: 'A');
            final engine = TxEngine<List<_Item>>([base]);
            final older = ListUpdateElementTxOperation<_Item, String>(
              name: 'older',
              id: 'tx-older',
              baseVersion: 0,
              touchedElementKeys: const {'name'},
              element: base,
              optimisticUpdate: (current) => current.copyWith(name: 'A-old'),
              updateElement: (item) async => 'server-old',
              apply: (optimisticElement, result) =>
                  optimisticElement.copyWith(name: result),
            );
            final newer = ListUpdateElementTxOperation<_Item, String>(
              name: 'newer',
              id: 'tx-newer',
              baseVersion: 0,
              touchedElementKeys: const {'name'},
              element: base,
              optimisticUpdate: (current) => current.copyWith(name: 'A-new'),
              updateElement: (item) async => 'server-new',
              apply: (optimisticElement, result) =>
                  optimisticElement.copyWith(name: result),
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

            expect(engine.computeVisible(), [_item(id: 1, name: 'A-new')]);

            final newerResult = await newer.commit(engine.confirmed);
            engine.settleSuccess(newer.id, newerResult, newer.applyConfirmed);
            expect(engine.confirmed, [_item(id: 1, name: 'server-new')]);

            final olderResult = await older.commit(engine.confirmed);
            engine.settleSuccess(older.id, olderResult, older.applyConfirmed);

            expect(engine.confirmed, [_item(id: 1, name: 'server-new')]);
            expect(engine.computeVisible(), [_item(id: 1, name: 'server-new')]);
            expect(engine.confirmedVersion, 1);
          },
        );
      });

      group('TransactionalMutationMixin usage', () {
        late _ItemListTxRepo repo;

        setUp(() {
          repo = _ItemListTxRepo();
        });

        tearDown(() async {
          await repo.destroy();
        });

        test(
          'applies optimistic add immediately and settles to confirmed add',
          () async {
            repo.data([_item(id: 1, name: 'A')]);
            final commit = Completer<int>();
            final operation = ListAddElementTxOperation<_Item, int>(
              name: 'add-item',
              id: repo.nextTxId(),
              baseVersion: 0,
              element: _item(id: -1, name: 'temp'),
              createElement: () => commit.future,
              apply: (optimisticElement, result) =>
                  _item(id: result, name: 'B'),
            );

            final future = repo.transact<int>(
              operation,
              analyticsAttributes: const {'source': 'test'},
            );

            await Future<void>.delayed(Duration.zero);
            expect(repo.state.requireData, [
              _item(id: 1, name: 'A'),
              _item(id: -1, name: 'temp'),
            ]);
            expect(analytics.events, contains('mutation_add-item'));
            expect(telemetry.runSpanNames, containsAll(['add-item', 'try_0']));

            commit.complete(2);
            final result = await future;

            expect(result.success, isTrue);
            expect(result.value, 2);
            expect(result.visibleState, [
              _item(id: 1, name: 'A'),
              _item(id: 2, name: 'B'),
            ]);
            expect(repo.state.requireData, [
              _item(id: 1, name: 'A'),
              _item(id: 2, name: 'B'),
            ]);
            expect(
              analytics.eventProperties['mutation_add-item']?['source'],
              'test',
            );
          },
        );

        test('rolls back optimistic remove when commit fails', () async {
          final a = _item(id: 1, name: 'A');
          final b = _item(id: 2, name: 'B');
          repo.data([a, b]);
          final commit = Completer<int>();
          final operation = ListRemoveElementTxOperation<_Item, int>(
            name: 'remove-item',
            id: repo.nextTxId(),
            baseVersion: 0,
            element: b,
            removeElement: () => commit.future,
            apply: (optimisticElement, result) => _item(id: result, name: 'B'),
          );

          final future = repo.transact<int>(operation);

          await Future<void>.delayed(Duration.zero);
          expect(repo.state.requireData, [a]);

          commit.completeError(StateError('network'));
          final result = await future;

          expect(result.success, isFalse);
          expect(result.error, isA<StateError>());
          expect(repo.state.requireData, [a, b]);
        });

        test(
          'keeps newer overlapping update visible when older commit settles later',
          () async {
            final base = _item(id: 1, name: 'A');
            repo.data([base]);
            final olderCommit = Completer<String>();
            final newerCommit = Completer<String>();

            final older = ListUpdateElementTxOperation<_Item, String>(
              name: 'edit-name-older',
              id: repo.nextTxId(),
              baseVersion: 0,
              touchedElementKeys: const {'name'},
              element: base,
              optimisticUpdate: (current) => current.copyWith(name: 'A-older'),
              updateElement: (item) => olderCommit.future,
              apply: (optimisticElement, result) =>
                  optimisticElement.copyWith(name: result),
            );
            final newer = ListUpdateElementTxOperation<_Item, String>(
              name: 'edit-name-newer',
              id: repo.nextTxId(),
              baseVersion: 0,
              touchedElementKeys: const {'name'},
              element: base,
              optimisticUpdate: (current) => current.copyWith(name: 'A-newer'),
              updateElement: (item) => newerCommit.future,
              apply: (optimisticElement, result) =>
                  optimisticElement.copyWith(name: result),
            );

            final olderFuture = repo.transact<String>(older);
            final newerFuture = repo.transact<String>(newer);

            await Future<void>.delayed(Duration.zero);
            expect(repo.state.requireData, [_item(id: 1, name: 'A-newer')]);

            newerCommit.complete('server-newer');
            final newerResult = await newerFuture;
            expect(newerResult.success, isTrue);
            expect(repo.state.requireData, [
              _item(id: 1, name: 'server-newer'),
            ]);

            olderCommit.complete('server-older');
            final olderResult = await olderFuture;
            expect(olderResult.success, isTrue);
            expect(repo.state.requireData, [
              _item(id: 1, name: 'server-newer'),
            ]);
            expect(
              analytics.events,
              containsAll([
                'mutation_edit-name-older',
                'mutation_edit-name-newer',
              ]),
            );
          },
        );
      });
    });
  });
}

class _ItemListTxRepo extends Repo<List<_Item>>
    with
        RepoLifecycleMixin<List<_Item>>,
        RepoLifecycleHooksMixin<List<_Item>>,
        TelemetryMixin,
        TransactionalMutationMixin<List<_Item>> {
  _ItemListTxRepo() {
    installTransactionHooks();
  }

  @override
  String get logTag => '_ItemListTxRepo';
}

_Item _item({required int id, required String name}) {
  return _Item(id: id, name: name);
}

class _Item {
  const _Item({required this.id, required this.name});

  final int id;
  final String name;

  _Item copyWith({int? id, String? name}) {
    return _Item(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _Item && other.id == id && other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => '_Item(id: $id, name: $name)';
}
