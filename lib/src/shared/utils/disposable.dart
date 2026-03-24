import 'dart:async';
import 'package:get_it/get_it.dart' as get_it;
import 'package:meta/meta.dart';

/// Shared teardown contract for disposable runtime objects.
///
/// Normalizes cleanup into a single [destroy] method that also satisfies
/// `get_it` disposal hooks.
///
/// Modules, repos, services, and datasources all need one teardown shape that
/// works both manually and through DI scope disposal.
///
/// Implementers define [destroy], and [onDispose] delegates to it.
///
/// `get_it` calls [onDispose], not [destroy], so this mixin bridges the two.
///
/// For example:
/// ```dart
/// class Worker with Disposable {
///   @override
///   Future<void> destroy() async {}
/// }
/// ```
///
/// {@category shared}

mixin Disposable on Object implements get_it.Disposable {
  /// Disposes of the resource.
  FutureOr<void> destroy();

  @override
  @nonVirtual
  FutureOr<dynamic> onDispose() => destroy();
}
