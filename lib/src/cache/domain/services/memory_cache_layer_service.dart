import 'package:grumpy/grumpy.dart';

/// L1 in-memory cache layer.
abstract class MemoryCacheLayerService extends CacheLayerService {
  /// Returns the DI-registered implementation of [MemoryCacheLayerService].
  ///
  /// Shorthand for [Service.get].
  factory MemoryCacheLayerService() {
    return Service.get<MemoryCacheLayerService>();
  }

  /// Internal constructor for concrete memory-layer implementations.
  MemoryCacheLayerService.internal() : super.internal();

  @override
  int get priority => 0;

  @override
  String get group => '${super.group}.MemoryCacheLayerService';
}
