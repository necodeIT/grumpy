import 'package:grumpy/grumpy.dart';
import 'package:grumpy/src/domain/models/repo_state.dart';

/// An error indicating an invalid state in a [RepoState].
///
/// Thrown when attempting to access data or error information
/// that is not available in the current state.
class RepoStateError extends StateError {

  /// Creates a [RepoStateError] for the given [state] with an optional [message].
  RepoStateError(this.state, super.message);
  /// The [RepoState] that caused this error.
  final RepoState state;
}
