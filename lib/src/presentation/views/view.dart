/// The presentation of a route of type [T].
abstract class View<T> {
  /// Creates a [View].
  const View();

  /// Builds a preview presentation of [T] while the route is being validated.
  ///
  /// This can be used to show a loading indicator or a placeholder while
  /// a guard is being checked.
  ///
  /// Note: It is unsafe to perform navigation actions or to use
  /// any module-dependent resources in this method, as the module
  /// may not have been fully initialized yet when this method is called.
  T preview();

  /// Builds the final presentation of [T] once the route has been validated.
  T build();
}
