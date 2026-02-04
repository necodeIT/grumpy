import 'package:grumpy/grumpy.dart';

/// An error indicating that no data is available in a [RepoState].
///
/// Thrown when attempting to access data from a state that does not contain data.
class NoRepoDataError extends RepoStateError {
  /// Creates a [NoRepoDataError] for the given [state].
  NoRepoDataError(RepoState state)
    : super(state, 'No data available in RepoState. Current state: $state');
}
