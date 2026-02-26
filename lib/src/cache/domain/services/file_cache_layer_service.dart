import 'package:grumpy/grumpy.dart';

/// L2 persistent cache layer.
abstract class FileCacheLayerService extends CacheLayerService {
  /// Returns the DI-registered implementation of [FileCacheLayerService].
  ///
  /// Shorthand for [Service.get].
  factory FileCacheLayerService() {
    return Service.get<FileCacheLayerService>();
  }

  /// Internal constructor for concrete file-layer implementations.
  const FileCacheLayerService.internal() : super.internal();

  @override
  int get priority => 1;

  @override
  String get group => '${super.group}.FileCacheLayerService';
}
