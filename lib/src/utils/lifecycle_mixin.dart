import 'dart:async';

import 'package:meta/meta.dart';
import 'package:grumpy/grumpy.dart';

/// Mixin that provides lifecycle methods for classes that need to respond
/// to different stages of their lifecycle.
///
/// Classes that mix in [LifecycleMixin] should implement the following methods:
/// - [initialize]: Called when the object is instantiated.
/// - [activate]: Called when the object is activated (e.g., after creation or
///   returning from the background).
/// - [deactivate]: Called when the object is deactivated.
/// - [dependenciesChanged]: Called when the object's dependencies have changed.
/// - [free]: Called when the object is being disposed of.
abstract mixin class LifecycleMixin implements Disposable {
  bool _isDisposed = false;

  /// Called when the the object is instantiated in the constructor.
  ///
  /// Any initial setup or resource allocation should be handled here.
  FutureOr<void> initialize();

  /// Called when the object is being activated (e.g. after object is created
  /// or coming back from background).
  ///
  /// Any resources that should be resumed or re-initialized when the object
  /// becomes active should be handled here.
  FutureOr<void> activate();

  /// Called when the object is being deactivated.
  ///
  /// Any resources that should be paused or suspended when the object
  /// is not active should be handled here.
  /// Note that [deactivate] may be called multiple times during the
  /// lifecycle of the object, so it should not release resources
  /// that are needed for the object's entire lifetime.
  FutureOr<void> deactivate();

  /// Called when the object's dependencies have changed.
  FutureOr<void> dependenciesChanged();

  /// Disposes of the object and releases any resources.
  /// This method should be overridden to perform cleanup tasks.
  ///
  /// You can safely assume that [free] will be called only once.
  @override
  @mustCallSuper
  FutureOr<void> free() async {
    if (_isDisposed) {
      throw StateError('Resource has already been disposed.');
    }

    _isDisposed = true;
  }

  @override
  @nonVirtual
  FutureOr<void> onDispose() => free();
}

/// Mixin that adds lifecycle callbacks to a [Repo].
mixin RepoLifecycleMixin<T> on Repo<T> {
  /// Called when a new data value is emitted.
  void onEmitData(T data) {}

  /// Called when an error occurs.
  void onEmitError(Object error, StackTrace? stackTrace) {}

  /// Called when the loading state changes.
  void onEmitLoading() {}

  @override
  void data(value) {
    super.data(value);

    onEmitData(value);
  }

  @override
  void error(Object error, [StackTrace? stackTrace]) {
    super.error(error, stackTrace);

    onEmitError(error, stackTrace);
  }

  @override
  void loading() {
    super.loading();
    onEmitLoading();
  }
}
