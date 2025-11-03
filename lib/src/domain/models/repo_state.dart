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
  /// Throws a [NoRepoDataError] if [hasData] is false.
  T get requireData {
    if (this is RepoDataState<T>) {
      return (this as RepoDataState<T>).value;
    } else {
      throw NoRepoDataError(this);
    }
  }

  /// Returns this state as an error state containing the error information.
  /// Throws a [RepoStateError] if [hasError] is false.
  RepoErrorState<T> get asError {
    if (this is RepoErrorState<T>) {
      return this as RepoErrorState<T>;
    } else {
      throw RepoStateError(this, 'No error available in RepoState.');
    }
  }

  /// Returns this state as a loading state containg information for how long it has been loading.
  /// Throws a [RepoStateError] if [isLoading] is false.
  RepoLoadingState<T> get asLoading {
    if (this is RepoLoadingState<T>) {
      return this as RepoLoadingState<T>;
    } else {
      throw RepoStateError(this, 'Not a loading state in RepoState.');
    }
  }

  /// Pattern matches on the type of this state and invokes the corresponding callback.
  ///
  /// **Example:**
  /// ```dart
  /// final message = state.when(
  ///   data: (dataState) => 'Data loaded: ${dataState.value}',
  ///   loading: (loadingState) => 'Loading for ${loadingState.elapsed.inSeconds} seconds',
  ///   error: (errorState) => 'Error occurred: ${errorState.error}',
  /// );
  /// ```
  R when<R>({
    required R Function(RepoDataState<T> data) data,
    required R Function(RepoLoadingState<T> loading) loading,
    required R Function(RepoErrorState<T> error) error,
  });
}

/// Represents a data state in a [Repo] indicating successful data retrieval.
class RepoDataState<T> extends RepoState<T> {
  /// The data value contained in this state.
  final T value;

  /// Creates a [RepoDataState] with the given [value].
  const RepoDataState(this.value);

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

/// Represents a loading state in a [Repo] indicating that data is being fetched.
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

/// Represents an error state in a [Repo].
class RepoErrorState<T> extends RepoState<T> {
  /// The error object associated with this state.
  final Object error;

  /// The optional stack trace associated with this error.
  final StackTrace? stackTrace;

  /// Creates a [RepoErrorState] with the given [error] and optional [stackTrace].
  const RepoErrorState(this.error, [this.stackTrace]);

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

/// An error indicating an invalid state in a [RepoState].
///
/// Thrown when attempting to access data or error information
/// that is not available in the current state.
class RepoStateError extends StateError {
  /// The [RepoState] that caused this error.
  final RepoState state;

  /// Creates a [RepoStateError] for the given [state] with an optional [message].
  RepoStateError(this.state, super.message);
}

/// An error indicating that no data is available in a [RepoState].
///
/// Thrown when attempting to access data from a state that does not contain data.
class NoRepoDataError extends RepoStateError {
  /// Creates a [NoRepoDataError] for the given [state].
  NoRepoDataError(RepoState state)
    : super(state, 'No data available in RepoState. Current state: $state');
}
