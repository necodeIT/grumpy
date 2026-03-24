import 'package:grumpy/grumpy.dart';
import 'package:meta/meta.dart';

/// Factory contract for constructing transaction engines across all state types.
///
/// Creates a fresh [TxEngine] for any repo state type.
///
/// DI cannot register every generic specialization of `TxEngine<TState>`
/// directly, but repos still need a simple typed entry point.
///
/// [TxEngine] delegates construction to this DI-resolved service, and the
/// concrete implementation chooses which engine to instantiate.
///
/// Implementations should return non-singleton engines because each repo owns
/// its own transaction timeline.
///
/// - `TState`: the repo state type requested by [create].
/// - [seed]: the initial state that may inform engine selection.
///
/// For example:
/// ```dart
/// final factory = TxEngineFactoryService();
/// ```
///
/// {@category transactions}

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
