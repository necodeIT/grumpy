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

  group("Repo reactiveness", () {
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

    group("Stream emissions", () {
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

      test("Receives multiple state changes", () {
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
