import 'package:grumpy/grumpy.dart';

/// L1 in-memory cache layer.
///
/// {@category cache}

abstract class MemoryCacheLayerService extends CacheLayerService {
  /// Returns the DI-registered implementation of [MemoryCacheLayerService].
  ///
  /// Shorthand for [Service.get].
  factory MemoryCacheLayerService() {
    return Service.get<MemoryCacheLayerService>();
  }

  /// Internal constructor for concrete memory-layer implementations.
  const MemoryCacheLayerService.internal() : super.internal();

  @override
  int get priority => 0;

  @override
  String get group => '${super.group}.MemoryCacheLayerService';
}
