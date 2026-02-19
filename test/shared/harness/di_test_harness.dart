import 'package:get_it/get_it.dart';
import 'package:grumpy/grumpy.dart';
import 'package:grumpy/src/transactions/infra/services/default_tx_engine_factory_service.dart';

Future<GetIt> resetTestDi({bool dispose = true}) async {
  final di = GetIt.instance;
  await di.reset(dispose: dispose);
  return di;
}

Future<GetIt> configureObservabilityDi({
  bool dispose = true,
  required TelemetryService telemetry,
  required AnalyticsService analytics,
  bool includeTxEngineFactory = false,
}) async {
  final di = await resetTestDi(dispose: dispose);
  di.registerSingleton<TelemetryService>(telemetry);
  di.registerSingleton<AnalyticsService>(analytics);
  if (includeTxEngineFactory) {
    di.registerSingleton<TxEngineFactoryService>(
      DefaultTxEngineFactoryService(),
    );
  }
  return di;
}
