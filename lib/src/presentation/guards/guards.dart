/// A guard is responsible for determining whether a route can be activated.
abstract class Guard {
  /// The path to redirect to if the guard denies activation.
  final String? redirectTo;

  /// Creates a [Guard].
  const Guard({this.redirectTo});

  /// Determines whether the route can be activated.
  Future<bool> canActivate();
}
