// this is the base class.
// ignore: models_must_extend_model
import 'package:grumpy_annotations/grumpy_annotations.dart';

/// Marker base type for public value objects in Grumpy.
///
/// Provides a shared base type for models that belong to the pure domain/value
/// layer.
///
/// Keeping models behind one contract makes annotations, lint rules, and API
/// expectations consistent across the package.
///
/// The class is intentionally empty. The type itself is the signal.
///
/// [Model] is for value-like types, not runtime services or stateful objects.
///
/// For example:
/// ```dart
/// class UserModel extends Model {
///   const UserModel(this.id);
///
///   final String id;
/// }
/// ```
///
/// {@category shared}

@BaseClass(allowedLayers: {.domain}, forceSuffix: false)
abstract class Model {
  /// Marker class for all models used in the grumpy.
  const Model();
}
