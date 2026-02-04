import 'package:grumpy/grumpy.dart';

/// Represents the data state of a [Repo].
abstract class RepoState<T> extends Model {
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
