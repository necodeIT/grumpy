import 'package:grumpy/grumpy.dart';

/// L2 persistent cache layer.
abstract class FileCacheLayerService extends CacheLayerService {
  /// Internal constructor for concrete file-layer implementations.
  FileCacheLayerService.internal() : super.internal();

  @override
  int get priority => 1;

  @override
  String get group => '${super.group}.FileCacheLayerService';
}
