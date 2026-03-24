import 'dart:async';

import 'package:grumpy_annotations/grumpy_annotations.dart';
import 'package:meta/meta.dart';
import 'package:grumpy/grumpy.dart';

/// Lifecycle contract for runtime-managed objects.
///
/// Defines the standard lifecycle phases for modules, repos, and other managed
/// runtime objects.
///
/// Grumpy coordinates many objects through DI scopes and module activation, so
/// they need a predictable lifecycle vocabulary.
///
/// Types implement [initialize], [activate], [deactivate],
/// [dependenciesChanged], and [destroy].
///
/// - [initialize] is expected to run during construction for most concrete
///   types.
/// - [deactivate] is a warm stop, not final disposal.
/// - [destroy] is final and may only succeed once.
///
/// For example:
/// ```dart
/// class Worker with LifecycleMixin {
///   @override
///   Future<void> initialize() async {}
///
///   @override
///   Future<void> activate() async {}
///
///   @override
///   Future<void> deactivate() async {}
///
///   @override
///   Future<void> dependenciesChanged() async {}
/// }
/// ```
abstract mixin class LifecycleMixin implements Disposable {
  bool _isDisposed = false;

  /// Called when the the object is instantiated in the constructor.
  ///
  /// Any initial setup or resource allocation should be handled here.
  @MustCallInConstructor(exempt: [Module, Injectable])
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
  /// You can safely assume that [destroy] will be called only once.
  @override
  @mustCallSuper
  FutureOr<void> destroy() async {
    if (_isDisposed) {
      throw StateError('Resource has already been disposed.');
    }

    _isDisposed = true;
  }

  @override
  @nonVirtual
  FutureOr<void> onDispose() => destroy();
}

/// Repo-specific lifecycle emission hooks.
///
/// Adds callbacks around [Repo.data], [Repo.loading], and [Repo.error].
///
/// Repo-focused mixins such as cache, persistence, and transactions need to
/// react to state emissions without overriding core repo behavior repeatedly.
///
/// The mixin intercepts repo state emitters and forwards them to overridable
/// callback methods.
///
/// Callbacks run after the repo has already emitted the new state.
///
/// - `T`: the repo's data type.
///
/// For example:
/// ```dart
/// class UserRepo extends Repo<User> with RepoLifecycleMixin<User> {
///   @override
///   void onEmitData(User data) {}
/// }
/// ```
///
/// {@category shared}

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
