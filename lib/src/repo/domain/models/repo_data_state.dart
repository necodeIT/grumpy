import 'package:grumpy/grumpy.dart';

/// Represents a data state in a [Repo] indicating successful data retrieval.
class RepoDataState<T> extends RepoState<T> {
  /// Creates a [RepoDataState] with the given [value].
  const RepoDataState(this.value);

  /// The data value contained in this state.
  final T value;

  @override
  String toString() {
    return 'RepoDataState(value: $value)';
  }

  @override
  R when<R>({
    required R Function(RepoDataState<T> data) data,
    required R Function(RepoLoadingState<T> loading) loading,
    required R Function(RepoErrorState<T> error) error,
  }) {
    return data(this);
  }
}
