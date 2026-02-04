// this is the base class.
// ignore: models_must_extend_model
import 'package:grumpy_annotations/grumpy_annotations.dart';

/// Marker class for all models used in the grumpy.
@BaseClass(allowedLayers: {.domain}, forceSuffix: false)
abstract class Model {
  /// Marker class for all models used in the grumpy.
  const Model();
}
