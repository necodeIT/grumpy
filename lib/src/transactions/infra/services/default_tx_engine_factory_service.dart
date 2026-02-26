import 'package:grumpy/grumpy.dart';
import 'package:grumpy/src/transactions/infra/services/default_tx_engine.dart';

/// Default transaction-engine factory used by [RootModule].
///
/// This implementation always returns [DefaultTxEngine] and keeps engine
/// creation policy centralized in one DI-managed service.
class DefaultTxEngineFactoryService extends TxEngineFactoryService {
  /// Creates the default transaction-engine factory service.
  DefaultTxEngineFactoryService() : super.internal();

  @override
  TxEngine<TState> create<TState>(TState seed) => DefaultTxEngine<TState>();

  @override
  String get logTag => 'DefaultTxEngineFactoryService';

  @override
  void destroy() {}
}
