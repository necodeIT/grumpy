import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:grumpy/grumpy.dart';
import 'package:test/test.dart';

void main() {
  final di = GetIt.instance;

  setUp(() async {
    await di.reset();
    di.registerSingleton<TelemetryService>(_TestTelemetryService());
    di.registerSingleton<AnalyticsService>(_TestAnalyticsService());
  });

  tearDown(() async {
    await di.reset();
  });

  group('Spec: operation_based_mutations (TxEngine)', () {
    test('replays disjoint pending operations together', () {
      final engine = TxEngine<int>(10);
      engine.enqueue(
        id: 'a',
        touchedKeys: const <String>{'left'},
        apply: (value) => value + 2,
      );
      engine.enqueue(
        id: 'b',
        touchedKeys: const <String>{'right'},
        apply: (value) => value * 3,
      );

      expect(
        engine.computeVisible(),
        36,
        reason:
            'Spec: operation_based_mutations §7 requires disjoint touched keys to compose naturally.',
      );
    });

    test('newer pending op wins for overlapping touched keys', () {
      final engine = TxEngine<int>(5);
      engine.enqueue(
        id: 'older',
        touchedKeys: const <String>{'count'},
        apply: (value) => value + 1,
      );
      engine.enqueue(
        id: 'newer',
        touchedKeys: const <String>{'count'},
        apply: (value) => value + 4,
      );

      expect(
        engine.computeVisible(),
        9,
        reason:
            'Spec: operation_based_mutations §7 defines newer-wins optimistic projection for overlapping keys.',
      );
    });

    test(
      'successful settlement applies confirmed mapping and increments version',
      () {
        final engine = TxEngine<int>(7);
        engine.enqueue(
          id: 'tx',
          touchedKeys: const <String>{'count'},
          apply: (value) => value + 1,
        );

        engine.settleSuccess<int>('tx', 11, (confirmed, result) => result);

        expect(
          engine.confirmed,
          11,
          reason:
              'Spec: operation_based_mutations §8.2 requires applyConfirmed output to update confirmed state.',
        );
        expect(
          engine.confirmedVersion,
          1,
          reason:
              'Spec: operation_based_mutations §8.2 requires monotonic confirmed version increments on confirmed updates.',
        );
        expect(
          engine.pending,
          isEmpty,
          reason:
              'Spec: operation_based_mutations §8.2 removes settled operation from the pending queue.',
        );
      },
    );

    test(
      'successful settlement with null applyConfirmed keeps confirmed unchanged',
      () {
        final engine = TxEngine<int>(7);
        engine.enqueue(
          id: 'tx',
          touchedKeys: const <String>{'count'},
          apply: (value) => value + 1,
        );

        engine.settleSuccess<int>('tx', 999, (confirmed, result) => null);

        expect(
          engine.confirmed,
          7,
          reason:
              'Spec: operation_based_mutations §6.1 allows applyConfirmed to return null to keep confirmed unchanged.',
        );
        expect(
          engine.confirmedVersion,
          0,
          reason:
              'Spec: operation_based_mutations §8.2 only increments confirmed version when confirmed state changes.',
        );
      },
    );

    test('settling an overshadowed older op does not overwrite newer intent', () {
      final engine = TxEngine<int>(5);
      engine.enqueue(
        id: 'older',
        touchedKeys: const <String>{'count'},
        apply: (value) => value + 1,
      );
      engine.enqueue(
        id: 'newer',
        touchedKeys: const <String>{'count'},
        apply: (value) => value + 4,
      );

      engine.settleSuccess<int>('newer', 20, (confirmed, result) => result);
      engine.settleSuccess<int>('older', 100, (confirmed, result) => result);

      expect(
        engine.confirmed,
        20,
        reason:
            'Spec: operation_based_mutations §7 requires newer overlapping intent to remain authoritative after settlement.',
      );
    });

    test(
      'failed settlement removes operation and recomputes from remaining pending',
      () {
        final engine = TxEngine<int>(10);
        engine.enqueue(
          id: 'first',
          touchedKeys: const <String>{'a'},
          apply: (value) => value + 2,
        );
        engine.enqueue(
          id: 'second',
          touchedKeys: const <String>{'b'},
          apply: (value) => value * 2,
        );

        engine.settleFailure('first');

        expect(
          engine.pending.map((e) => e.id).toList(),
          ['second'],
          reason:
              'Spec: operation_based_mutations §8.3 requires failed operation removal from pending queue.',
        );
        expect(
          engine.computeVisible(),
          20,
          reason:
              'Spec: operation_based_mutations §5 and §8.3 require visible replay from confirmed plus remaining pending ops.',
        );
      },
    );
  });

  group('Spec: operation_based_mutations (TransactionalMutationMixin)', () {
    test('throws when transaction hooks are not installed', () async {
      final repo = _UninstalledTxRepo();
      repo.data(1);

      expect(
        () => repo.transact<int>(
          _op(
            name: 'x',
            id: 'x',
            optimistic: (v) => v + 1,
            commit: () async => 2,
          ),
        ),
        throwsA(isA<StateError>()),
        reason:
            'Spec: operation_based_mutations §6.3 requires lifecycle-installed transaction hooks before using transact.',
      );

      await repo.free();
    });

    test('applies optimistic state immediately before commit settles', () async {
      final repo = _TxRepo()..data(3);
      final commit = Completer<int>();

      final future = repo.transact<int>(
        _op(
          name: 'increment',
          id: repo.nextTxId(),
          optimistic: (value) => value + 1,
          commit: () => commit.future,
          applyConfirmed: (_, result) => result,
        ),
      );

      await Future<void>.delayed(Duration.zero);
      expect(
        repo.state.requireData,
        4,
        reason:
            'Spec: operation_based_mutations §1 and §8.1 require immediate optimistic projection on enqueue.',
      );

      commit.complete(4);
      final result = await future;

      expect(
        result.success,
        isTrue,
        reason:
            'Spec: operation_based_mutations §8.2 requires success outcome for successful commit.',
      );
      expect(
        repo.state.requireData,
        4,
        reason:
            'Spec: operation_based_mutations §5 requires visible state to match replayed confirmed state after settlement.',
      );
    });

    test('retries commit according to retry policy', () async {
      final repo = _TxRepo()..data(2);
      var attempts = 0;

      final result = await repo.transact<int>(
        _op(
          name: 'retrying',
          id: repo.nextTxId(),
          optimistic: (value) => value + 1,
          commit: () async {
            attempts++;
            if (attempts < 3) throw StateError('retry');
            return 3;
          },
          applyConfirmed: (_, v) => v,
        ),
        retryPolicy: const RetryPolicy(delay: Duration.zero, maxAttempts: 3),
      );

      expect(
        attempts,
        3,
        reason:
            'Spec: operation_based_mutations §8.4 requires commit retries to respect RetryPolicy max attempts.',
      );
      expect(
        result.success,
        isTrue,
        reason:
            'Spec: operation_based_mutations §8.4 keeps optimistic op active across retries until commit succeeds.',
      );
      expect(
        repo.state.requireData,
        3,
        reason:
            'Spec: operation_based_mutations §8.2 requires confirmed update after eventual successful retry.',
      );
    });

    test('returns failure result and rolls back failed optimistic op', () async {
      final repo = _TxRepo()..data(9);

      final result = await repo.transact<int>(
        _op(
          name: 'failing',
          id: repo.nextTxId(),
          optimistic: (value) => value + 5,
          commit: () async => throw StateError('boom'),
        ),
      );

      expect(
        result.success,
        isFalse,
        reason:
            'Spec: operation_based_mutations §8.3 requires failure outcome when commit fails.',
      );
      expect(
        result.error,
        isA<StateError>(),
        reason:
            'Spec: operation_based_mutations §12 requires failure payload to be returned to caller.',
      );
      expect(
        repo.state.requireData,
        9,
        reason:
            'Spec: operation_based_mutations §8.3 requires rollback by removing failed pending op and replaying remaining queue.',
      );
    });

    test('nextTxId yields unique per-repo identifiers', () async {
      final repo = _TxRepo();

      final first = repo.nextTxId();
      final second = repo.nextTxId();

      expect(
        first == second,
        isFalse,
        reason:
            'Spec: operation_based_mutations §6.1 requires each operation id to be unique per enqueue.',
      );

      await repo.free();
    });
  });
}

SimpleTxOperation<int, int> _op({
  required String name,
  required String id,
  required int Function(int current) optimistic,
  required Future<int> Function() commit,
  int? Function(int confirmed, int result)? applyConfirmed,
}) {
  return SimpleTxOperation<int, int>(
    name: name,
    id: id,
    baseVersion: 0,
    optimisticApply: optimistic,
    commit: commit,
    applyConfirmed: applyConfirmed ?? (confirmed, result) => result,
    touchedKeys: const <String>{'count'},
  );
}

class _TxRepo extends Repo<int>
    with
        RepoLifecycleMixin<int>,
        RepoLifecycleHooksMixin<int>,
        TelemetryMixin,
        TransactionalMutationMixin<int> {
  _TxRepo() {
    installTransactionHooks();
  }

  @override
  String get logTag => '_TxRepo';
}

class _UninstalledTxRepo extends Repo<int>
    with
        RepoLifecycleMixin<int>,
        RepoLifecycleHooksMixin<int>,
        TelemetryMixin,
        TransactionalMutationMixin<int> {
  @override
  String get logTag => '_UninstalledTxRepo';
}

class _TestTelemetryService extends TelemetryService {
  _TestTelemetryService() : super.internal();

  @override
  Future<T> runSpan<T>(
    String name,
    FutureOr<T> Function() operation, {
    Map<String, dynamic>? attributes,
  }) async {
    return await operation();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }

  @override
  String get logTag => '_TestTelemetryService';
}

class _TestAnalyticsService extends AnalyticsService {
  _TestAnalyticsService() : super.internal();

  @override
  Future<void> trackEvent(
    String name, {
    Map<String, dynamic>? properties,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return Future<void>.value();
  }

  @override
  String get logTag => '_TestAnalyticsService';
}
