import 'package:grumpy/grumpy.dart';
import 'package:meta/meta.dart';

/// Factory contract for constructing transaction engines across all state types.
///
/// Why this exists:
/// - Dart/DI containers cannot register "all generic specializations" of
///   `TxEngine<TState>` directly with a single typed binding.
/// - Repositories still need a simple `TxEngine(seed)` entrypoint.
/// - Applications may need different engine implementations based on state type
///   or runtime preferences.
///
/// This service provides a single DI-resolved abstraction that can build a
/// `TxEngine<TState>` for any `TState`, while keeping selection logic in one
/// place (typically root module wiring).
///
/// Typical usage:
/// 1. Root module binds a concrete [TxEngineFactoryService].
/// 2. [TxEngine] factory delegates to this service.
/// 3. Concrete implementation chooses and returns a fresh engine instance.
///
/// Implementations should return non-singleton engines because each repo
/// instance owns its own transactional timeline.
abstract class TxEngineFactoryService extends Service {
  /// Resolves the configured transaction-engine factory from DI.
  factory TxEngineFactoryService() => Service.get<TxEngineFactoryService>();

  /// Internal constructor for implementations.
  TxEngineFactoryService.internal() : super();

  /// Creates a transaction engine for [TState].
  ///
  /// [seed] is provided so implementations can choose engines based on state
  /// type/value characteristics if desired. Callers should still oil the
  /// returned engine explicitly.
  TxEngine<TState> create<TState>(TState seed);

  @override
  String get group => '${super.group}.TxEngineFactoryService';

  @override
  String get logTag => 'TxEngineFactoryService';

  @override
  @nonVirtual
  bool get singelton => true;
}
