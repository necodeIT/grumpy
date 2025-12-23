import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:modular_foundation/modular_foundation.dart';
import 'package:test/test.dart';

void main() {
  group('Middleware', () {
    test('stores path, children, and middleware', () {
      final middleware = _CountingMiddleware();
      final child = const Route<String, Object>(path: 'child');

      final route = Route<String, Object>(
        path: 'parent',
        children: [child],
        middleware: [middleware],
      );

      expect(route.path, 'parent');
      expect(route.children, contains(child));
      expect(route.middleware, contains(middleware));
      expect(route.toString(), contains('parent'));
    });

    test('root factory creates a slash path container', () {
      final child = const Route<String, Object>(path: 'home');

      final root = Route<String, Object>.root([child]);

      expect(root.path, '/');
      expect(root.children, [child]);
    });
  });

  group('ModuleRoute', () {
    test('exposes module and toString details', () {
      final module = _DummyModule();

      final route = ModuleRoute<String, Object>(
        path: 'feature',
        module: module,
      );

      expect(route.path, 'feature');
      expect(route.module, same(module));
      expect(route.middleware, isEmpty);
      expect(route.toString(), contains('feature'));
      expect(route.toString(), contains(module.runtimeType.toString()));
    });
  });

  group('LeafRoute', () {
    test('delegates preview and build to view', () async {
      final view = _TestLeaf();
      final route = LeafRoute<String, Object>(path: 'leaf', view: view);
      final context = const RouteContext(fullPath: '/leaf');

      final preview = route.view.preview(context);
      final built = await route.view.build(context);

      expect(preview, equals('preview:/leaf'));
      expect(built, equals('built:/leaf'));
      expect(route.toString(), contains('leaf'));
    });
  });

  group('RouteContext', () {
    test('parses uri components and exposes helpers', () {
      final context = const RouteContext(
        fullPath: '/users/42?tab=profile&tab=activity#details',
        pathParams: {'id': '42'},
        queryParams: {'tab': 'profile'},
        queryParamsAll: {
          'tab': ['profile', 'activity'],
        },
        fragment: 'details',
      );

      expect(context.uri.path, '/users/42');
      expect(context.uri.queryParameters['tab'], 'activity');
      expect(context.uri.fragment, 'details');

      expect(context.getPathParam('id'), '42');
      expect(context.getQueryParam('tab'), 'profile');
      expect(context.get('id'), '42');
      expect(context['tab'], 'profile');
      expect(context.hasPathParam('missing'), isFalse);
      expect(context.hasQueryParam('tab'), isTrue);
      expect(context.has('id'), isTrue);
      expect(
        context.queryParamsAll['tab'],
        containsAll(['profile', 'activity']),
      );
    });

    test('toString includes context details', () {
      final context = const RouteContext(
        fullPath: '/items/1',
        pathParams: {'itemId': '1'},
        queryParams: {'source': 'test'},
        fragment: 'frag',
      );

      final description = context.toString();
      expect(description, contains('/items/1'));
      expect(description, contains('itemId'));
      expect(description, contains('source'));
      expect(description, contains('frag'));
    });
  });

  group('RoutingKitRoutingService', () {
    late GetIt di;
    late _RootTestModule root;
    late RoutingService<String, _Cfg> routing;

    setUp(() async {
      di = GetIt.instance;
      await di.reset();
      root = _RootTestModule(const _Cfg('cfg'));
      await root.initialize();
      routing = di.get<RoutingService<String, _Cfg>>();
    });

    tearDown(() async {
      await di.reset();
    });

    test('navigation fails when route is not a leaf', () async {
      final results = <String>[];

      await expectLater(
        () => routing.navigate('/feature', callback: results.add),
        throwsA(isA<ArgumentError>()),
      );

      expect(results, isEmpty);
    });

    test('navigating to nested leaf activates required modules', () async {
      final results = <String>[];

      await routing.navigate('/feature/child', callback: results.add);

      expect(results, ['preview:/feature/child', 'built:/feature/child']);
      expect(root.featureModule.activateCalls, 1);
    });
  });
}

class _CountingMiddleware extends Middleware {
  int calls = 0;

  @override
  Future<RouteContext> call(RouteContext context) async {
    calls++;
    return context;
  }

  @override
  String toString() {
    return 'CountingMiddleware(calls: $calls)';
  }
}

class _DummyModule extends Module<String, Object> {
  @override
  Future<void> activate() async {}

  @override
  Future<void> deactivate() async {}

  @override
  Future<void> dependenciesChanged() async {}

  @override
  Future<void> dispose() async {
    await super.dispose();
  }

  @override
  Future<void> initialize() async {
    await super.initialize();
  }

  @override
  List<Route<String, Object>> get routes => const [];
}

class _TestLeaf extends Leaf<String> {
  int previewCalls = 0;
  int buildCalls = 0;

  @override
  String preview(RouteContext ctx) {
    previewCalls++;
    return 'preview:${ctx.fullPath}';
  }

  @override
  Future<String> build(RouteContext ctx) async {
    buildCalls++;
    return 'built:${ctx.fullPath}';
  }
}

class _TestLeaf2 extends Leaf<String> {
  @override
  String preview(RouteContext ctx) => 'preview:${ctx.fullPath}';

  @override
  Future<String> build(RouteContext ctx) async => 'built:${ctx.fullPath}';
}

class _FeatureModule extends Module<String, _Cfg> {
  int activateCalls = 0;

  @override
  Future<void> activate() async {
    activateCalls++;
  }

  @override
  Future<void> deactivate() async {}

  @override
  Future<void> dependenciesChanged() async {}

  @override
  Future<void> initialize() async {
    await super.initialize();
  }

  @override
  Future<void> dispose() async {
    await super.dispose();
  }

  @override
  List<Route<String, _Cfg>> get routes => [
    LeafRoute<String, _Cfg>(path: 'child', view: _TestLeaf2()),
  ];
}

class _RootTestModule extends RootModule<String, _Cfg> {
  _RootTestModule(super.cfg) : featureModule = _FeatureModule();

  final _FeatureModule featureModule;

  @override
  List<Route<String, _Cfg>> get routes => [
    ModuleRoute<String, _Cfg>(path: 'feature', module: featureModule),
  ];

  @override
  FutureOr<void> activate() {}

  @override
  FutureOr<void> deactivate() {}

  @override
  FutureOr<void> dependenciesChanged() {}
}

class _Cfg {
  const _Cfg(this.id);

  final String id;
}
