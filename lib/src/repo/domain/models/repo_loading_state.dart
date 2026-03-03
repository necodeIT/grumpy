import 'package:grumpy/grumpy.dart';

/// Represents a loading state in a [Repo] indicating that data is being fetched.
///
/// {@category repo}

class RepoLoadingState<T> extends RepoState<T> {
  /// Creates a [RepoLoadingState].
  const RepoLoadingState(this.timeStamp);

  /// The timestamp when this loading state was created.
  final DateTime timeStamp;

  /// The duration since this loading state was created.
  Duration get elapsed => DateTime.now().difference(timeStamp);

  @override
  String toString() {
    return 'RepoLoadingState(timeStamp: $timeStamp)';
  }

  @override
  R when<R>({
    required R Function(RepoDataState<T> data) data,
    required R Function(RepoLoadingState<T> loading) loading,
    required R Function(RepoErrorState<T> error) error,
  }) {
    return loading(this);
  }
}
