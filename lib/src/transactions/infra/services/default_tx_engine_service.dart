import 'package:grumpy/grumpy.dart';

/// Default transaction engine factory.
class DefaultTxEngineService extends TxEngineService {
  /// Default transaction engine factory.
  const DefaultTxEngineService() : super.internal();

  @override
  TxEngine<TState> create<TState>(TState initial) {
    return TxEngine<TState>(initial);
  }

  @override
  bool get singelton => true;

  @override
  String get group => '${super.group}.TxEngineService';

  @override
  String get logTag => 'DefaultTxEngineService';

  @override
  void free() {}
}
