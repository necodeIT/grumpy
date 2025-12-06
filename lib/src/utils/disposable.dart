import 'dart:async';
import 'package:get_it/get_it.dart' as get_it;
import 'package:meta/meta.dart';

/// An interface for disposable resources.
mixin Disposable on Object implements get_it.Disposable {
  /// Disposes of the resource.
  FutureOr<void> dispose();

  @override
  @nonVirtual
  FutureOr<dynamic> onDispose() => dispose();
}
