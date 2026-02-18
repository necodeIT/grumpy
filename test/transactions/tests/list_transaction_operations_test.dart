import 'package:grumpy/grumpy.dart';
import 'package:test/test.dart';

import '../harness/harness.dart';

void main() {
  group('ListAddElementTxOperation', () {
    test('applies optimistic addition and commit-confirmed addition', () async {
      final operation = ListAddElementTxOperation<int, int>(
        name: 'add',
        id: 'tx-1',
        baseVersion: 0,
        element: 2,
        createElement: () async => 20,
        apply: (optimisticElement, result) => optimisticElement + result,
      );

      expect(operation.optimisticApply([1]), [1, 2]);
      expect(operation.applyConfirmed([1], 20), [1, 22]);
      await expectLater(operation.commit([1]), completion(20));
    });

    test('uses provided rollback callback', () {
      final operation = ListAddElementTxOperation<int, int>(
        name: 'add',
        id: 'tx-1',
        baseVersion: 0,
        element: 2,
        createElement: () async => 20,
        apply: (optimisticElement, result) => optimisticElement + result,
        shouldRollbackOnError: (error, stackTrace) => false,
      );

      expect(operation.shouldRollback(Exception('x'), null), isFalse);
    });
  });

  group('ListRemoveElementTxOperation', () {
    test('applies optimistic removal and commit-confirmed removal', () async {
      final operation = ListRemoveElementTxOperation<int, int>(
        name: 'remove',
        id: 'tx-2',
        baseVersion: 0,
        element: 2,
        removeElement: () async => 20,
        apply: (optimisticElement, result) => optimisticElement,
      );

      expect(operation.optimisticApply([1, 2, 3]), [1, 3]);
      expect(operation.applyConfirmed([1, 2, 3], 20), [1, 3]);
      await expectLater(operation.commit([1, 2, 3]), completion(20));
    });

    test('uses provided rollback callback', () {
      final operation = ListRemoveElementTxOperation<int, int>(
        name: 'remove',
        id: 'tx-2',
        baseVersion: 0,
        element: 2,
        removeElement: () async => 20,
        apply: (optimisticElement, result) => optimisticElement,
        shouldRollbackOnError: (error, stackTrace) => false,
      );

      expect(operation.shouldRollback(Exception('x'), null), isFalse);
    });
  });

  group('ListUpdateElementTxOperation', () {
    test('applies optimistic update and commit-confirmed update', () async {
      final element = const TestItem(id: 1, name: 'A');
      final operation = ListUpdateElementTxOperation<TestItem, String>(
        name: 'update',
        id: 'tx-3',
        baseVersion: 0,
        touchedElementKeys: const {'name'},
        element: element,
        optimisticUpdate: (current) =>
            current.copyWith(name: '${current.name}!'),
        updateElement: (target) async => 'server',
        apply: (optimisticElement, result) =>
            optimisticElement.copyWith(name: result),
      );

      expect(operation.optimisticApply([element]), [
        const TestItem(id: 1, name: 'A!'),
      ]);
      expect(operation.applyConfirmed([element], 'server'), [
        const TestItem(id: 1, name: 'server'),
      ]);
      await expectLater(operation.commit([element]), completion('server'));
      expect(operation.touchedKeys, {'$element.name'});
    });

    test('returns null when confirmed list does not contain element', () {
      final operation = ListUpdateElementTxOperation<TestItem, String>(
        name: 'update',
        id: 'tx-3',
        baseVersion: 0,
        touchedElementKeys: const {'name'},
        element: const TestItem(id: 1, name: 'A'),
        optimisticUpdate: (current) =>
            current.copyWith(name: '${current.name}!'),
        updateElement: (target) async => 'server',
        apply: (optimisticElement, result) =>
            optimisticElement.copyWith(name: result),
      );

      expect(
        operation.applyConfirmed(const [TestItem(id: 2, name: 'B')], 'server'),
        isNull,
      );
    });

    test('uses provided rollback callback', () {
      final operation = ListUpdateElementTxOperation<TestItem, String>(
        name: 'update',
        id: 'tx-3',
        baseVersion: 0,
        touchedElementKeys: const {'name'},
        element: const TestItem(id: 1, name: 'A'),
        optimisticUpdate: (current) =>
            current.copyWith(name: '${current.name}!'),
        updateElement: (target) async => 'server',
        apply: (optimisticElement, result) =>
            optimisticElement.copyWith(name: result),
        shouldRollbackOnError: (error, stackTrace) => false,
      );

      expect(operation.shouldRollback(Exception('x'), null), isFalse);
    });
  });
}
