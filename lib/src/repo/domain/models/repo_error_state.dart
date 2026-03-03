import 'package:grumpy/grumpy.dart';

/// Represents an error state in a [Repo].
///
/// {@category repo}

class RepoErrorState<T> extends RepoState<T> {
  /// Creates a [RepoErrorState] with the given [error] and optional [stackTrace].
  const RepoErrorState(this.error, [this.stackTrace]);

  /// The error object associated with this state.
  final Object error;

  /// The optional stack trace associated with this error.
  final StackTrace? stackTrace;

  @override
  String toString() {
    return 'RepoErrorState(error: $error, stackTrace: $stackTrace)';
  }

  @override
  R when<R>({
    required R Function(RepoDataState<T> data) data,
    required R Function(RepoLoadingState<T> loading) loading,
    required R Function(RepoErrorState<T> error) error,
  }) {
    return error(this);
  }
}
