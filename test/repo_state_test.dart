import 'package:test/test.dart';
import 'package:modular_foundation/modular_foundation.dart';

void main() {
  test('RepoState data', () {
    final state = RepoState.data(42);
    expect(state.hasData, isTrue);
    expect(state.isLoading, isFalse);
    expect(state.hasError, isFalse);
    expect(state.data, equals(42));
    expect(() => state.asError, throwsStateError);
    expect(state.requireData, equals(42));
  });

  test('RepoState loading', () {
    final state = RepoState<int>.loading();
    expect(state.hasData, isFalse);
    expect(state.isLoading, isTrue);
    expect(state.hasError, isFalse);
    expect(state.data, isNull);
    expect(() => state.requireData, throwsStateError);
  });

  test('RepoState error', () {
    final error = Exception('Test error');
    final state = RepoState<int>.error(error);
    expect(state.hasData, isFalse);
    expect(state.isLoading, isFalse);
    expect(state.hasError, isTrue);
    expect(state.data, isNull);
    expect(() => state.requireData, throwsStateError);
    expect(state.asError.error, equals(error));
  });
}
