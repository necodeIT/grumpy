/// Coordinates temporary runtime work that can delay dependency registration.
///
/// Consumers use this contract before treating an unregistered dependency as
/// missing. The application runtime can finish work such as navigation and
/// module activation that may register the dependency in the meantime.
///
/// Implementations should return immediately when no relevant work is pending.
///
/// {@category shared}
abstract interface class DependencyReadiness {
  /// Waits for currently pending work that may register dependencies.
  ///
  /// Work started while waiting should also be included before this method
  /// completes, so callers observe a stable readiness boundary.
  Future<void> waitForPendingDependencies();
}
