import 'package:grumpy/grumpy.dart';

/// Represents a successful repo data state.
///
/// Wraps the current loaded repo value.
///
/// The repo state machine needs an explicit success variant instead of using a
/// nullable value.
///
/// [RepoDataState] stores the current [value] and satisfies [RepoState.when].
///
/// This is the only [RepoState] variant where [RepoState.requireData] succeeds.
///
/// - `T`: the repo data type.
/// - [value]: the loaded data payload.
///
/// For example:
/// ```dart
/// const RepoDataState<int>(1);
/// ```
///
/// {@category repo}

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
