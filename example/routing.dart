// Example file
// ignore_for_file: avoid_print

import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:modular_foundation/modular_foundation.dart';

class _Config {}

class _RootModule extends RootModule<_Config, String> {
  @override
  final List<Route<String, _Config>> routes = [
    LeafRoute<String, _Config>(
      path: '/home',
      view: _TestView(),
      children: [
        LeafRoute<String, _Config>(path: '/details', view: _TestView()),
      ],
    ),
    ModuleRoute<String, _Config>(path: '/test/:id', module: _TestModule()),
  ];

  _RootModule(super.cfg) {
    initialize();
  }

  @override
  Route<String, _Config> get root => Route.root(routes);

  @override
  noSuchMethod(Invocation invocation) {
    print('Called: ${invocation.memberName}');
  }
}

class _TestView extends Leaf<String> {
  @override
  String preview(RouteContext ctx) {
    return 'Preview';
  }

  @override
  FutureOr<String> build(RouteContext ctx) {
    return 'Built View';
  }
}

class _TestModule extends Module<_Config, String> {
  @override
  final List<Route<String, _Config>> routes = [
    LeafRoute<String, _Config>(path: '/a', view: _TestView()),
  ];

  @override
  noSuchMethod(Invocation invocation) {
    print('Called: ${invocation.memberName}');
  }
}

Future<void> main() async {
  Logger.root.onRecord.listen((record) {
    print(record);
  });

  final rootModule = _RootModule(_Config());

  final router = GetIt.I<RoutingService<String, _Config>>();

  await router.navigate('/test/123we/a', callback: print);

  print(router.currentContext());

  await Future.delayed(const Duration(seconds: 1));
}
