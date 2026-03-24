import 'package:grumpy/grumpy.dart';
import 'package:meta/meta.dart';

/// Per-repo transaction state machine with optimistic replay.
///
/// Tracks confirmed state, pending optimistic operations, and the current
/// visible state projection for one repo instance.
///
/// Optimistic mutation needs a deterministic replay engine that is separate
/// from the repo itself.
///
/// The engine stores confirmed state plus a pending queue, then recomputes
/// visible state by replaying pending operations according to conflict policy.
///
/// Engines are per repo instance and must not be singletons.
///
/// - `TState`: the repo state type managed by the engine.
/// - [seed]: the initial confirmed state passed to the factory constructor.
///
/// For example:
/// ```dart
/// final engine = TxEngine<SettingsState>(seed);
/// ```
///
/// {@category transactions}

abstract class TxEngine<TState> extends Service {
  /// Resolves a transaction engine from DI.
  factory TxEngine(TState seed) {
    final engine = TxEngineFactoryService().create<TState>(seed);
    engine.oil(seed);
    return engine;
  }

  /// Internal constructor for concrete implementations.
  TxEngine.internal() : super();

  /// Seeds or reseeds the engine with a confirmed baseline.
  void oil(TState seed);

  /// Current confirmed state baseline.
  TState get confirmed;

  /// Monotonic confirmed version.
  int get confirmedVersion;

  /// Read-only pending operations queue.
  List<TxPending<TState>> get pending;

  /// Computes current visible state by replaying projected pending ops.
  ///
  /// This should be used after enqueue/settle to produce render state.
  TState computeVisible();

  /// Enqueues a new optimistic operation.
  ///
  /// The returned [TxPending] can be used for debugging or tracing.
  TxPending<TState> enqueue({
    required String id,
    required Set<String> touchedKeys,
    required TState Function(TState current) apply,
  });

  /// Settles operation [id] as success and optionally updates confirmed state.
  ///
  /// Settlement rules:
  /// - if the operation cannot be found, it is ignored.
  /// - if the operation is overshadowed by a newer settled op touching at least
  ///   one same key, confirmed state is not overwritten.
  /// - if [applyConfirmed] returns non-null, confirmed state updates and version
  ///   increments by one.
  void settleSuccess<TResult>(
    String id,
    TResult result,
    TState? Function(TState confirmed, TResult result) applyConfirmed,
  );

  /// Settles operation [id] as failure by removing it from pending queue.
  ///
  /// Caller is expected to recompute visible state after this operation.
  void settleFailure(String id);

  @override
  String get group => '${super.group}.TxEngine';

  @override
  String get logTag => 'TxEngine';

  @override
  void destroy();

  @override
  @nonVirtual
  bool get singelton => false;
}
