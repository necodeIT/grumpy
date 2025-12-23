import 'package:modular_foundation/modular_foundation.dart';
import 'package:test/test.dart';

void main() {
  late _TestRepo repo;

  setUp(() {
    repo = _TestRepo();
  });

  tearDown(() async {
    try {
      await repo.dispose();
    } on StateError {
      // Repo already disposed in the test.
    }
  });

  group('Repo reactiveness', () {
    test('Initial state is loading', () {
      expect(repo.state.isLoading, isTrue);
    });

    test('Data state updates correctly', () {
      repo.setData(100);
      expect(repo.state.hasData, isTrue);
      expect(repo.state.data, equals(100));
    });

    test('Loading state updates correctly', () {
      repo.setData(50);
      repo.setLoading();
      expect(repo.state.isLoading, isTrue);
    });

    test('Error state updates correctly', () {
      final error = Exception('Test error');
      repo.setError(error);
      expect(repo.state.hasError, isTrue);
      expect(repo.state.asError.error, equals(error));
    });

    test('Error state stores stack trace', () {
      final error = Exception('Test error with stack trace');
      final stackTrace = StackTrace.current;
      repo.setError(error, stackTrace);

      final state = repo.state.asError;
      expect(state.error, equals(error));
      expect(state.stackTrace, same(stackTrace));
    });

    test('Dispose closes the stream', () async {
      await repo.dispose();
      expect(
        () => repo.setData(123),
        throwsA(
          isA<StateError>().having(
            (err) => err.message,
            'message',
            'Cannot add new events after calling close',
          ),
        ),
      );
    });

    group('Stream emissions', () {
      test('Emits loading initially', () {
        expectLater(
          repo.stream,
          emitsInOrder([
            isA<RepoState<int>>().having(
              (s) => s.isLoading,
              'isLoading',
              isTrue,
            ),
          ]),
        );
      });

      test('Emits data state', () {
        expectLater(
          repo.stream,
          emitsInOrder([
            isA<RepoState<int>>().having(
              (s) => s.isLoading,
              'isLoading',
              isTrue,
            ),
            isA<RepoState<int>>().having((s) => s.hasData, 'hasData', isTrue),
          ]),
        );

        repo.setData(200);
      });

      test('Emits error state', () {
        final error = Exception('Stream error');
        expectLater(
          repo.stream,
          emitsInOrder([
            isA<RepoState<int>>().having(
              (s) => s.isLoading,
              'isLoading',
              isTrue,
            ),
            isA<RepoState<int>>().having((s) => s.hasError, 'hasError', isTrue),
          ]),
        );

        repo.setError(error);
      });

      test('Receives multiple state changes', () {
        final error = Exception('Another error');
        expectLater(
          repo.stream,
          emitsInOrder([
            isA<RepoState<int>>().having(
              (s) => s.isLoading,
              'isLoading',
              isTrue,
            ),
            isA<RepoState<int>>().having((s) => s.hasData, 'hasData', isTrue),
            isA<RepoState<int>>().having(
              (s) => s.isLoading,
              'isLoading',
              isTrue,
            ),
            isA<RepoState<int>>().having((s) => s.hasError, 'hasError', isTrue),
          ]),
        );

        repo.setData(300);
        repo.setLoading();
        repo.setError(error);
      });
    });
  });

  group('RepoState', () {
    test('data exposes value and throws on invalid conversions', () {
      final state = const RepoState.data(42);
      expect(state.hasData, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.hasError, isFalse);
      expect(state.data, equals(42));
      expect(state.requireData, equals(42));
      expect(() => state.asError, throwsA(isA<RepoStateError>()));
      expect(() => state.asLoading, throwsA(isA<RepoStateError>()));
    });

    test('loading exposes elapsed time and guards data access', () {
      final state = RepoState<int>.loading();
      expect(state.hasData, isFalse);
      expect(state.isLoading, isTrue);
      expect(state.hasError, isFalse);
      expect(state.data, isNull);
      final loadingState = state.asLoading;
      expect(loadingState.timeStamp, isA<DateTime>());
      expect(loadingState.elapsed, isA<Duration>());
      expect(loadingState.elapsed.isNegative, isFalse);
      expect(() => state.requireData, throwsA(isA<NoRepoDataError>()));
      expect(() => state.asError, throwsA(isA<RepoStateError>()));
    });

    test('error exposes metadata and throws on data access', () {
      final error = Exception('Test error');
      final stackTrace = StackTrace.current;
      final state = RepoState<int>.error(error, stackTrace);
      expect(state.hasData, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.hasError, isTrue);
      expect(state.data, isNull);
      expect(() => state.requireData, throwsA(isA<NoRepoDataError>()));
      expect(() => state.asLoading, throwsA(isA<RepoStateError>()));
      final errorState = state.asError;
      expect(errorState.error, equals(error));
      expect(errorState.stackTrace, same(stackTrace));
    });
  });
}

class NoOpTelemetryService extends TelemetryService {
  @override
  noSuchMethod(Invocation invocation) {}
}

class _TestRepo extends Repo<int> {
  _TestRepo() {
    initialize();
  }

  void setData(int value) => data(value);
  void setLoading() => loading();
  void setError(Object error, [StackTrace? stackTrace]) =>
      super.error(error, stackTrace);
}
