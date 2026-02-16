import 'package:grumpy/grumpy.dart';

/// L1 in-memory cache layer.
abstract class MemoryCacheLayerService extends CacheLayerService {
  /// Internal constructor for concrete memory-layer implementations.
  MemoryCacheLayerService.internal() : super.internal();

  @override
  int get priority => 0;

  @override
  String get group => '${super.group}.MemoryCacheLayerService';
}
