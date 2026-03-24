import 'package:grumpy/grumpy.dart';

/// Represents a repo error state.
///
/// Carries the failure that prevented the repo from producing usable data.
///
/// Error handling should be an explicit repo-state variant rather than an
/// out-of-band side effect.
///
/// [RepoErrorState] stores the [error] and optional [stackTrace].
///
/// This variant may still be emitted even if the repo had data previously; the
/// repo decides its own transition semantics.
///
/// - `T`: the repo data type.
/// - [error], [stackTrace]: failure details.
///
/// For example:
/// ```dart
/// const RepoErrorState<int>(StateError('boom'));
/// ```
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
