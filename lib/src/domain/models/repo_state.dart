import 'package:modular_foundation/modular_foundation.dart';

/// Represents the data state of a [Repo].
abstract class RepoState<T> implements Model {
  /// Creates a new instance of [RepoState].
  const RepoState();

  /// Creates a [RepoDataState] with the given [value].
  ///
  /// This indicates that the repository has successfully loaded data.
  const factory RepoState.data(T value) = RepoDataState<T>;

  /// Creates a [RepoLoadingState] indicating that the repository is currently loading data.
  factory RepoState.loading() => RepoLoadingState<T>(DateTime.now());

  /// Creates a [RepoErrorState] indicating that the repository has encountered an error.
  const factory RepoState.error(Object error, [StackTrace? stackTrace]) =
      RepoErrorState<T>;

  /// True if this state contains data.
  bool get hasData => this is RepoDataState<T>;

  /// True if this state is loading.
  bool get isLoading => this is RepoLoadingState<T>;

  /// True if this state represents an error.
  bool get hasError => this is RepoErrorState<T>;

  /// The data contained in this state, or null if [hasData] is false.
  T? get data =>
      this is RepoDataState<T> ? (this as RepoDataState<T>).value : null;

  /// Returns the data contained in this state.
  /// Throws a [StateError] if [hasData] is false.
  T get requireData {
    if (this is RepoDataState<T>) {
      return (this as RepoDataState<T>).value;
    } else {
      throw StateError('No data available in RepoState.');
    }
  }

  /// Returns this state as an error state containing the error information.
  /// Throws a [StateError] if [hasError] is false.
  RepoErrorState<T> get asError {
    if (this is RepoErrorState<T>) {
      return this as RepoErrorState<T>;
    } else {
      throw StateError('No error available in RepoState.');
    }
  }

  /// Returns this state as a loading state containg information for how long it has been loading.
  /// Throws a [StateError] if [isLoading] is false.
  RepoLoadingState<T> get asLoading {
    if (this is RepoLoadingState<T>) {
      return this as RepoLoadingState<T>;
    } else {
      throw StateError('Not a loading state in RepoState.');
    }
  }
}

/// Represents a data state in a [Repo] indicating successful data retrieval.
class RepoDataState<T> extends RepoState<T> {
  /// The data value contained in this state.
  final T value;

  /// Creates a [RepoDataState] with the given [value].
  const RepoDataState(this.value);
}

/// Represents a loading state in a [Repo] indicating that data is being fetched.
class RepoLoadingState<T> extends RepoState<T> {
  /// Creates a [RepoLoadingState].
  const RepoLoadingState(this.timeStamp);

  /// The timestamp when this loading state was created.
  final DateTime timeStamp;

  /// The duration since this loading state was created.
  Duration get elapsed => DateTime.now().difference(timeStamp);
}

/// Represents an error state in a [Repo].
class RepoErrorState<T> extends RepoState<T> {
  /// The error object associated with this state.
  final Object error;

  /// The optional stack trace associated with this error.
  final StackTrace? stackTrace;

  /// Creates a [RepoErrorState] with the given [error] and optional [stackTrace].
  const RepoErrorState(this.error, [this.stackTrace]);
}
