import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';

/// {@template hook_installer}
/// An annotation indicating that the annotated method
/// must be called in the constructor of the class
/// that uses the mixin defining the method.
///
/// If [concreteOnly] is true (default), the requirement
/// applies only to concrete classes, and calling it in an abstract
/// class's constructor is considered a violation.
/// Otherwise, it applies to the class even if it's abstract.
///
/// Note: If any class in the inheritance chain calls the
/// annotated method in its constructor, the requirement
/// is considered satisfied for subclasses.
/// {@endtemplate}
@Target({TargetKind.method})
@immutable
class MustCallInConstructor {
  /// If true (default), the requirement
  /// applies only to concrete classes, and calling it in an abstract
  /// class's constructor is considered a violation.
  /// Otherwise, it applies to the class even if it's abstract.
  final bool concreteOnly;

  /// {@macro hook_installer}
  const MustCallInConstructor({this.concreteOnly = true});
}

/// {@macro hook_installer}
const mustCallInConstructor = MustCallInConstructor();
