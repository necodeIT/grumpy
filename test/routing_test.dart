// irrelevant for testing purposes
// ignore_for_file: missing_override_of_must_be_overridden
import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:grumpy/grumpy.dart';
import 'package:test/test.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // this is not production code; it's just for test logging
    // ignore: avoid_print
    print(record);
  });

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
      final built = await route.view.content(context);

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
      await di.reset(dispose: false);
      root = _RootTestModule(const _Cfg('cfg'));
      await root.initialize();
      await root.activate();
      routing = di.get<RoutingService<String, _Cfg>>();
    });

    tearDown(() async {
      await di.reset(dispose: false);
    });

    test('navigation fails when route is not a leaf', () async {
      final results = <String>[];

      await expectLater(
        routing.navigate('/idk/', callback: (result, _) => results.add(result)),
        throwsA(isA<ArgumentError>()),
      );

      expect(results, isEmpty);
    });

    test('navigation fails when route is a module without root', () async {
      final results = <String>[];

      await expectLater(
        routing.navigate(
          '/module',
          callback: (result, _) => results.add(result),
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(results, isEmpty);
    });

    test('navigating to nested leaf activates required modules', () async {
      final results = <String>[];

      await routing.navigate(
        '/feature/child',
        callback: (result, _) => results.add(result),
      );

      expect(results, ['preview:/feature/child', 'built:/feature/child']);
      expect(root.featureModule.activateCalls, 1);
    });

    test(
      'final view waits until required module activation completes',
      () async {
        await di.reset(dispose: false);
        final delayedRoot = _DelayedActivationRootModule(const _Cfg('cfg'));
        await delayedRoot.initialize();
        await delayedRoot.activate();
        final delayedRouting = di.get<RoutingService<String, _Cfg>>();
        final results = <String>[];

        final navigation = delayedRouting.navigate(
          '/delayed/child',
          callback: (result, _) => results.add(result),
        );

        await delayedRoot.delayedModule.activationStarted.future;
        expect(results, ['preview:/delayed/child']);

        delayedRoot.delayedModule.releaseActivation();
        await navigation;

        expect(results, ['preview:/delayed/child', 'built:/delayed/child']);
        expect(delayedRoot.delayedModule.activateCalls, 1);
      },
    );

    test(
      'uses ModuleRoute root when navigating into module subroutes',
      () async {
        final results = <String>[];

        await expectLater(
          routing.navigate(
            '/feature/',
            callback: (result, _) => results.add(result),
          ),
          completes,
        );

        expect(results, ['preview:/feature/', 'built:/feature/']);
        expect(root.featureModule.activateCalls, 1);
      },
    );

    test('isActive returns false when no route is active', () {
      expect(routing.isActive('/feature/child'), isFalse);
      expect(routing.isActive('/feature', exact: false), isFalse);
    });

    test('isActive supports exact and partial matches', () async {
      await routing.navigate('/feature/child');

      expect(routing.isActive('/feature/child'), isTrue);
      expect(routing.isActive('/feature'), isFalse);
      expect(routing.isActive('/feature', exact: false), isTrue);
      expect(routing.isActive('/feature/sub', exact: false), isFalse);
    });

    test('isActive can ignore query params and fragments', () async {
      await routing.navigate('/feature/child?tab=profile#details');

      expect(routing.isActive('/feature/child?tab=profile#details'), isTrue);
      expect(routing.isActive('/feature/child'), isFalse);
      expect(routing.isActive('/feature/child', ignoreParams: true), isTrue);
      expect(
        routing.isActive('/feature', exact: false, ignoreParams: true),
        isTrue,
      );
    });

    test('navigate emits preview then final view events', () async {
      final callbackResults = <String>[];
      final streamEvents = <ViewChangedEvent<String, _Cfg>>[];
      final streamDone = Completer<void>();
      final sub = routing.viewStream.listen((event) {
        streamEvents.add(event);
        if (streamEvents.length == 2 && !streamDone.isCompleted) {
          streamDone.complete();
        }
      });

      await routing.navigate(
        '/feature/child',
        callback: (result, _) => callbackResults.add(result),
      );
      await streamDone.future;

      await sub.cancel();

      expect(callbackResults, [
        'preview:/feature/child',
        'built:/feature/child',
      ]);
      expect(streamEvents.length, 2);
      expect(streamEvents[0].isPreview, isTrue);
      expect(streamEvents[0].view, 'preview:/feature/child');
      expect(streamEvents[0].context, isNull);
      expect(streamEvents[0].config.id, 'cfg');
      expect(streamEvents[1].isPreview, isFalse);
      expect(streamEvents[1].view, 'built:/feature/child');
      expect(streamEvents[1].context?.fullPath, '/feature/child');
      expect(streamEvents[1].config.id, 'cfg');
    });

    test('skipPreview emits only final view in callback and stream', () async {
      final callbackResults = <String>[];
      final streamEvents = <ViewChangedEvent<String, _Cfg>>[];
      final streamDone = Completer<void>();
      final sub = routing.onViewChanged((event) {
        streamEvents.add(event);
        if (streamEvents.length == 1 && !streamDone.isCompleted) {
          streamDone.complete();
        }
      });

      await routing.navigate(
        '/feature/child',
        skipPreview: true,
        callback: (result, _) => callbackResults.add(result),
      );
      await streamDone.future;

      await sub.cancel();

      expect(callbackResults, ['built:/feature/child']);
      expect(streamEvents.length, 1);
      expect(streamEvents.single.isPreview, isFalse);
      expect(streamEvents.single.view, 'built:/feature/child');
      expect(streamEvents.single.context?.fullPath, '/feature/child');
      expect(streamEvents.single.config.id, 'cfg');
    });

    test(
      'onViewChanged subscription stops receiving events after cancel',
      () async {
        final events = <ViewChangedEvent<String, _Cfg>>[];
        final firstNavDone = Completer<void>();
        final sub = routing.onViewChanged((event) {
          events.add(event);
          if (events.length == 2 && !firstNavDone.isCompleted) {
            firstNavDone.complete();
          }
        });

        await routing.navigate('/feature/child');
        await firstNavDone.future;
        await sub.cancel();
        await routing.navigate('/feature/sub/final');
        await Future<void>.delayed(Duration.zero);

        expect(events.length, 2);
        expect(events[0].view, 'preview:/feature/child');
        expect(events[1].view, 'built:/feature/child');
      },
    );

    test(
      'middleware failure emits preview only and does not activate route',
      () async {
        final callbackResults = <String>[];
        final streamEvents = <ViewChangedEvent<String, _Cfg>>[];
        final streamDone = Completer<void>();
        final sub = routing.viewStream.listen((event) {
          streamEvents.add(event);
          if (streamEvents.length == 1 && !streamDone.isCompleted) {
            streamDone.complete();
          }
        });

        await routing.navigate(
          '/blocked',
          callback: (result, _) => callbackResults.add(result),
        );
        await streamDone.future;

        await sub.cancel();

        expect(callbackResults, ['preview:/blocked']);
        expect(streamEvents.length, 1);
        expect(streamEvents.single.isPreview, isTrue);
        expect(streamEvents.single.view, 'preview:/blocked');
        expect(routing.currentContext, isNull);
        expect(routing.isActive('/blocked'), isFalse);
      },
    );

    test('navigating to current uri is a no-op', () async {
      final initialEventsDone = Completer<void>();
      final streamEvents = <ViewChangedEvent<String, _Cfg>>[];
      final sub = routing.onViewChanged((event) {
        streamEvents.add(event);
        if (streamEvents.length == 2 && !initialEventsDone.isCompleted) {
          initialEventsDone.complete();
        }
      });

      await routing.navigate('/feature/child');
      await initialEventsDone.future;

      final repeatedCallbackResults = <String>[];
      await routing.navigate(
        '/feature/child',
        callback: (result, _) => repeatedCallbackResults.add(result),
      );

      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(repeatedCallbackResults, isEmpty);
      expect(streamEvents.length, 2);
      expect(root.featureModule.activateCalls, 1);
    });

    test(
      'listeners are notified once per successful navigation and can be removed',
      () async {
        final notifiedPaths = <String>[];
        void listener(Route<String, _Cfg> route) {
          notifiedPaths.add(route.path);
        }

        routing.addListener(listener);
        await routing.navigate('/feature/child');
        routing.removeListener(listener);
        await routing.navigate('/feature/sub/final');

        expect(notifiedPaths, ['child']);
      },
    );

    test(
      'middleware can rewrite context used by final view and active context',
      () async {
        final callbackResults = <String>[];

        await routing.navigate(
          '/rewrite?x=1#frag',
          callback: (result, _) => callbackResults.add(result),
        );

        expect(callbackResults, [
          'preview:/rewrite?x=1#frag',
          'built:/rewrite?from=middleware#rewritten',
        ]);
        expect(
          routing.currentContext?.fullPath,
          '/rewrite?from=middleware#rewritten',
        );
        expect(routing.isActive('/rewrite?from=middleware#rewritten'), isTrue);
        expect(routing.isActive('/rewrite?x=1#frag'), isFalse);
      },
    );

    test('failed middleware keeps previously active context', () async {
      await routing.navigate('/feature/child');
      expect(routing.currentContext?.fullPath, '/feature/child');

      await routing.navigate('/blocked');

      expect(routing.currentContext?.fullPath, '/feature/child');
    });

    test(
      'concurrent navigation to same path resolves via pending navigation',
      () async {
        final firstResults = <String>[];
        final secondResults = <String>[];

        final firstNavigation = routing.navigate(
          '/slow-pending',
          callback: (result, _) => firstResults.add(result),
        );

        await root.slowPendingMiddleware.started;

        final secondNavigation = routing.navigate(
          '/slow-pending',
          callback: (result, _) => secondResults.add(result),
        );

        root.slowPendingMiddleware.release();
        await Future.wait([firstNavigation, secondNavigation]);

        expect(firstResults, ['preview:/slow-pending', 'built:/slow-pending']);
        expect(secondResults, ['preview:/slow-pending', 'built:/slow-pending']);
        expect(root.slowPendingMiddleware.calls, 1);
      },
    );

    test(
      'concurrent same-path navigation does not duplicate view stream phases',
      () async {
        final events = <ViewChangedEvent<String, _Cfg>>[];
        final eventsDone = Completer<void>();
        final sub = routing.onViewChanged((event) {
          if (event.view.contains('/slow-pending')) {
            events.add(event);
            if (events.length == 2 && !eventsDone.isCompleted) {
              eventsDone.complete();
            }
          }
        });

        final firstNavigation = routing.navigate('/slow-pending');
        await root.slowPendingMiddleware.started;
        final secondNavigation = routing.navigate('/slow-pending');

        root.slowPendingMiddleware.release();
        await Future.wait([firstNavigation, secondNavigation]);
        await eventsDone.future;
        await sub.cancel();

        final previewEvents = events.where((event) => event.isPreview).toList();
        final finalEvents = events.where((event) => !event.isPreview).toList();

        expect(events.length, 2);
        expect(previewEvents.length, 1);
        expect(finalEvents.length, 1);
        expect(
          previewEvents.every((event) => event.view == 'preview:/slow-pending'),
          isTrue,
        );
        expect(
          finalEvents.every((event) => event.view == 'built:/slow-pending'),
          isTrue,
        );
      },
    );

    test(
      'skipPreview on forwarded navigation still does not duplicate stream events',
      () async {
        final events = <ViewChangedEvent<String, _Cfg>>[];
        final eventsDone = Completer<void>();
        final sub = routing.viewStream.listen((event) {
          if (event.view.contains('/slow-pending')) {
            events.add(event);
            if (events.length == 2 && !eventsDone.isCompleted) {
              eventsDone.complete();
            }
          }
        });

        final firstNavigation = routing.navigate('/slow-pending');
        await root.slowPendingMiddleware.started;
        final secondNavigation = routing.navigate(
          '/slow-pending',
          skipPreview: true,
        );

        root.slowPendingMiddleware.release();
        await Future.wait([firstNavigation, secondNavigation]);
        await eventsDone.future;
        await sub.cancel();

        final previewEvents = events.where((event) => event.isPreview).toList();
        final finalEvents = events.where((event) => !event.isPreview).toList();

        expect(events.length, 2);
        expect(previewEvents.length, 1);
        expect(finalEvents.length, 1);
        expect(previewEvents.single.view, 'preview:/slow-pending');
        expect(
          finalEvents.every((event) => event.view == 'built:/slow-pending'),
          isTrue,
        );
      },
    );

    test(
      'activates module dependencies for leading-slash module routes',
      () async {
        await di.reset(dispose: false);
        final slashRoot = _SlashRootModule(const _Cfg('cfg'));
        await slashRoot.initialize();
        await slashRoot.activate();
        final slashRouting = di.get<RoutingService<String, _Cfg>>();

        await slashRouting.navigate('/feature/child');

        expect(slashRoot.featureModule.activateCalls, 1);
        expect(slashRoot.dependencyModule.activateCalls, 1);
      },
    );

    test(
      'does not reinitialize routed module that was already mounted via imports',
      () async {
        await di.reset(dispose: false);
        final guardedRoot = _GuardedRootModule(const _Cfg('cfg'));
        await guardedRoot.initialize();
        await guardedRoot.activate();
        final guardedRouting = di.get<RoutingService<String, _Cfg>>();

        final repoBeforeNavigation = await di.getAsync<_GuardedRepo>();
        expect(repoBeforeNavigation.state.requireData, 'module repo data');
        expect(guardedRoot.guardedModule.initializeCalls, 1);

        await guardedRouting.navigate('/guarded/screen');

        final repoAfterNavigation = await di.getAsync<_GuardedRepo>();
        expect(repoAfterNavigation.state.requireData, 'guarded');
        expect(guardedRoot.guardedModule.initializeCalls, 1);
      },
    );
  });
}

class _CountingMiddleware extends Middleware<String, Object> {
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

  @override
  String get logTag => '_CountingMiddleware';
}

class _ThrowingMiddleware extends Middleware<String, _Cfg> {
  @override
  Future<RouteContext> call(RouteContext context) {
    throw StateError('middleware boom');
  }

  @override
  String toString() => '_ThrowingMiddleware()';

  @override
  String get logTag => '_ThrowingMiddleware';
}

class _RewriteContextMiddleware extends Middleware<String, _Cfg> {
  @override
  Future<RouteContext> call(RouteContext context) async {
    return RouteContext.fromUri(
      Uri.parse('/rewrite?from=middleware#rewritten'),
    );
  }

  @override
  String toString() => '_RewriteContextMiddleware()';

  @override
  String get logTag => '_RewriteContextMiddleware';
}

class _DelayedPassMiddleware extends Middleware<String, _Cfg> {
  int calls = 0;

  final Completer<void> _started = Completer<void>();
  final Completer<void> _release = Completer<void>();

  Future<void> get started => _started.future;

  void release() {
    if (!_release.isCompleted) {
      _release.complete();
    }
  }

  @override
  Future<RouteContext> call(RouteContext context) async {
    calls++;
    if (!_started.isCompleted) {
      _started.complete();
    }
    await _release.future;
    return context;
  }

  @override
  String toString() => '_DelayedPassMiddleware(calls: $calls)';

  @override
  String get logTag => '_DelayedPassMiddleware';
}

class _DummyModule extends Module<String, Object> {
  @override
  Future<void> activate() async {
    super.activate();
  }

  @override
  Future<void> deactivate() async {
    super.deactivate();
  }

  @override
  Future<void> dependenciesChanged() async {}

  @override
  Future<void> free() async {
    await super.free();
  }

  @override
  Future<void> initialize() async {
    await super.initialize();
  }

  @override
  List<Route<String, Object>> get routes => const [];
  @override
  String get logTag => '_DummyModule';
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
  Future<String> content(RouteContext ctx) async {
    buildCalls++;
    return 'built:${ctx.fullPath}';
  }
}

class _TestLeaf2 extends Leaf<String> {
  @override
  String preview(RouteContext ctx) => 'preview:${ctx.fullPath}';

  @override
  Future<String> content(RouteContext ctx) async => 'built:${ctx.fullPath}';
}

class _FeatureModule extends Module<String, _Cfg> {
  int activateCalls = 0;

  @override
  Future<void> activate() async {
    super.activate();
    activateCalls++;
  }

  @override
  Future<void> deactivate() async {
    super.deactivate();
  }

  @override
  Future<void> dependenciesChanged() async {}

  @override
  Future<void> initialize() async {
    await super.initialize();
  }

  @override
  Future<void> free() async {
    await super.free();
  }

  @override
  List<Route<String, _Cfg>> get routes => [
    LeafRoute<String, _Cfg>(path: 'child', view: _TestLeaf2()),
    Route<String, _Cfg>(
      path: 'sub',
      children: [LeafRoute<String, _Cfg>(path: 'final', view: _TestLeaf2())],
    ),
  ];
  @override
  String get logTag => '_FeatureModule';
}

class _RootTestModule extends RootModule<String, _Cfg> {
  _RootTestModule(super.cfg)
    : featureModule = _FeatureModule(),
      slowPendingMiddleware = _DelayedPassMiddleware();

  final _FeatureModule featureModule;
  final _DelayedPassMiddleware slowPendingMiddleware;

  @override
  List<Route<String, _Cfg>> get routes => [
    ModuleRoute<String, _Cfg>(
      path: 'feature',
      module: featureModule,
      root: LeafRoute<String, _Cfg>.root(_TestLeaf2()),
    ),
    LeafRoute<String, _Cfg>(
      path: 'blocked',
      view: _TestLeaf2(),
      middleware: [_ThrowingMiddleware()],
    ),
    LeafRoute<String, _Cfg>(
      path: 'rewrite',
      view: _TestLeaf2(),
      middleware: [_RewriteContextMiddleware()],
    ),
    LeafRoute<String, _Cfg>(
      path: 'slow-pending',
      view: _TestLeaf2(),
      middleware: [slowPendingMiddleware],
    ),
    ModuleRoute<String, _Cfg>(path: 'module', module: featureModule),
    const Route<String, _Cfg>(path: 'idk'),
  ];

  @override
  FutureOr<void> dependenciesChanged() {}
  @override
  String get logTag => '_RootTestModule';
}

class _Cfg {
  const _Cfg(this.id);

  final String id;
}

class _DependencyTrackingModule extends Module<String, _Cfg> {
  int activateCalls = 0;
  bool _active = false;

  @override
  Future<void> activate() async {
    super.activate();
    if (!_active) {
      activateCalls++;
      _active = true;
    }
  }

  @override
  Future<void> deactivate() async {
    super.deactivate();
    _active = false;
  }

  @override
  Future<void> dependenciesChanged() async {}

  @override
  List<Route<String, _Cfg>> get routes => const [];

  @override
  String get logTag => '_DependencyTrackingModule';
}

class _SlashFeatureModule extends Module<String, _Cfg> {
  _SlashFeatureModule(this.dependencyModule);

  final _DependencyTrackingModule dependencyModule;
  int activateCalls = 0;

  @override
  List<Module<String, _Cfg>> get imports => [dependencyModule];

  @override
  Future<void> activate() async {
    super.activate();
    activateCalls++;
  }

  @override
  Future<void> deactivate() async {
    super.deactivate();
  }

  @override
  Future<void> dependenciesChanged() async {}

  @override
  List<Route<String, _Cfg>> get routes => [
    LeafRoute<String, _Cfg>(path: 'child', view: _TestLeaf2()),
  ];

  @override
  String get logTag => '_SlashFeatureModule';
}

class _SlashRootModule extends RootModule<String, _Cfg> {
  _SlashRootModule(super.cfg) : dependencyModule = _DependencyTrackingModule();

  final _DependencyTrackingModule dependencyModule;
  late final _SlashFeatureModule featureModule = _SlashFeatureModule(
    dependencyModule,
  );

  @override
  List<Route<String, _Cfg>> get routes => [
    ModuleRoute<String, _Cfg>(
      path: '/feature',
      module: featureModule,
      root: LeafRoute<String, _Cfg>.root(_TestLeaf2()),
    ),
  ];

  @override
  FutureOr<void> dependenciesChanged() {}

  @override
  String get logTag => '_SlashRootModule';
}

class _RepoGuardMiddleware extends Middleware<String, _Cfg> {
  @override
  Future<RouteContext> call(RouteContext context) async {
    final repo = await Repo.get<_GuardedRepo>();
    repo.data('guarded');
    return context;
  }

  @override
  String get logTag => '_RepoGuardMiddleware';
}

class _GuardedRepo extends Repo<String> {
  _GuardedRepo(String initial) {
    data(initial);
  }

  @override
  String get logTag => '_GuardedRepo';
}

class _GuardedModule extends Module<String, _Cfg> {
  int initializeCalls = 0;

  @override
  void bindRepos(Bind<Repo, _Cfg> bind) {
    bind((_, _) => _GuardedRepo('module repo data'));
  }

  @override
  Future<void> initialize() async {
    initializeCalls++;
    await super.initialize();
  }

  @override
  Future<void> activate() async {
    super.activate();
  }

  @override
  Future<void> deactivate() async {
    super.deactivate();
  }

  @override
  Future<void> dependenciesChanged() async {}

  @override
  List<Route<String, _Cfg>> get routes => [
    LeafRoute<String, _Cfg>(
      path: 'screen',
      view: _TestLeaf2(),
      middleware: [_RepoGuardMiddleware()],
    ),
  ];

  @override
  String get logTag => '_GuardedModule';
}

class _GuardedRootModule extends RootModule<String, _Cfg> {
  _GuardedRootModule(super.cfg) : guardedModule = _GuardedModule();

  final _GuardedModule guardedModule;

  @override
  List<Module<String, _Cfg>> get imports => [guardedModule];

  @override
  List<Route<String, _Cfg>> get routes => [
    ModuleRoute<String, _Cfg>(
      path: 'guarded',
      module: guardedModule,
      root: LeafRoute<String, _Cfg>.root(_TestLeaf2()),
    ),
    LeafRoute<String, _Cfg>(path: 'redirect', view: _TestLeaf2()),
  ];

  @override
  FutureOr<void> dependenciesChanged() {}

  @override
  String get logTag => '_GuardedRootModule';
}

class _DelayedActivationModule extends Module<String, _Cfg> {
  int activateCalls = 0;
  final Completer<void> activationStarted = Completer<void>();
  final Completer<void> _releaseActivation = Completer<void>();

  void releaseActivation() {
    if (!_releaseActivation.isCompleted) {
      _releaseActivation.complete();
    }
  }

  @override
  Future<void> activate() async {
    if (!activationStarted.isCompleted) {
      activationStarted.complete();
    }
    await _releaseActivation.future;
    await super.activate();
    activateCalls++;
  }

  @override
  Future<void> deactivate() async {
    await super.deactivate();
  }

  @override
  Future<void> dependenciesChanged() async {}

  @override
  List<Route<String, _Cfg>> get routes => [
    LeafRoute<String, _Cfg>(path: 'child', view: _TestLeaf2()),
  ];

  @override
  String get logTag => '_DelayedActivationModule';
}

class _DelayedActivationRootModule extends RootModule<String, _Cfg> {
  _DelayedActivationRootModule(super.cfg)
    : delayedModule = _DelayedActivationModule();

  final _DelayedActivationModule delayedModule;

  @override
  List<Route<String, _Cfg>> get routes => [
    ModuleRoute<String, _Cfg>(
      path: 'delayed',
      module: delayedModule,
      root: LeafRoute<String, _Cfg>.root(_TestLeaf2()),
    ),
  ];

  @override
  FutureOr<void> dependenciesChanged() {}

  @override
  String get logTag => '_DelayedActivationRootModule';
}
