import 'dart:async';

/// An interface for disposable resources.
abstract class Disposable {
  /// Disposes of the resource.
  FutureOr<void> dispose();
}
