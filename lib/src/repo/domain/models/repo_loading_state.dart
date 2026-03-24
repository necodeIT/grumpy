import 'package:grumpy/grumpy.dart';

/// Represents an in-flight repo loading state.
///
/// Marks the repo as currently loading and records when loading began.
///
/// Consumers often need an explicit loading phase and sometimes the elapsed
/// loading duration.
///
/// [RepoLoadingState] stores [timeStamp] and derives [elapsed] from it.
///
/// [elapsed] is computed against `DateTime.now()`, so it changes over time.
///
/// - `T`: the repo data type.
/// - [timeStamp]: when the loading state was emitted.
///
/// For example:
/// ```dart
/// RepoLoadingState<int>(DateTime.now());
/// ```
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
