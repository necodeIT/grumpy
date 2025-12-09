import 'package:modular_foundation/modular_foundation.dart';
import 'package:test/test.dart';

void main() {
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
