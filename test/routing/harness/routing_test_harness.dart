import 'dart:async';
import 'package:grumpy/grumpy.dart';

class CountingMiddleware extends Middleware<String, Object> {
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
  String get logTag => 'CountingMiddleware';
}

class ThrowingMiddleware extends Middleware<String, Cfg> {
  @override
  Future<RouteContext> call(RouteContext context) {
    throw StateError('middleware boom');
  }

  @override
  String toString() => 'ThrowingMiddleware()';

  @override
  String get logTag => 'ThrowingMiddleware';
}

class RewriteContextMiddleware extends Middleware<String, Cfg> {
  @override
  Future<RouteContext> call(RouteContext context) async {
    return RouteContext.fromUri(
      Uri.parse('/rewrite?from=middleware#rewritten'),
    );
  }

  @override
  String toString() => 'RewriteContextMiddleware()';

  @override
  String get logTag => 'RewriteContextMiddleware';
}

class DelayedPassMiddleware extends Middleware<String, Cfg> {
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
  String toString() => 'DelayedPassMiddleware(calls: $calls)';

  @override
  String get logTag => 'DelayedPassMiddleware';
}

class DummyModule extends Module<String, Object> {
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
  String get logTag => 'DummyModule';
}

class DependentModule extends Module<String, Cfg> {
  static int initializeCalls = 0;
  static int activateCalls = 0;
  static bool initialized = false;
  static bool activated = false;
  @override
  String get logTag => 'DependentModule';

  @override
  List<Route<String, Cfg>> get routes => [LeafRoute.root(TestLeaf())];

  @override
  List<Module<String, Cfg>> get imports => [TrackingModule()];

  @override
  Future<void> initialize() async {
    initializeCalls++;
    await super.initialize();
    initialized = true;
  }

  @override
  FutureOr<void> activate() async {
    activateCalls++;
    await super.activate();
    activated = true;
  }

  static void resetTrackers() {
    initializeCalls = 0;
    activateCalls = 0;
    initialized = false;
    activated = false;
  }
}

class TrackingModule extends Module<String, Cfg> {
  static int initializeCalls = 0;
  static int activateCalls = 0;
  static bool initialized = false;
  static bool activated = false;

  static void resetTrackers() {
    initializeCalls = 0;
    activateCalls = 0;
    initialized = false;
    activated = false;
  }

  @override
  Future<void> initialize() async {
    initializeCalls++;
    await super.initialize();
    initialized = true;
  }

  @override
  Future<void> activate() async {
    activateCalls++;
    await super.activate();
    activated = true;
  }

  @override
  List<Route<String, Cfg>> get routes => const [];

  @override
  String get logTag => 'TrackingModule';
}

class TestLeaf extends Leaf<String> {
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

class TestLeaf2 extends Leaf<String> {
  @override
  String preview(RouteContext ctx) => 'preview:${ctx.fullPath}';

  @override
  Future<String> content(RouteContext ctx) async => 'built:${ctx.fullPath}';
}

class FeatureModule extends Module<String, Cfg> {
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
  List<Route<String, Cfg>> get routes => [
    LeafRoute<String, Cfg>(path: 'child', view: TestLeaf2()),
    Route<String, Cfg>(
      path: 'sub',
      children: [LeafRoute<String, Cfg>(path: 'final', view: TestLeaf2())],
    ),
  ];
  @override
  String get logTag => 'FeatureModule';
}

class RootTestModule extends RootModule<String, Cfg> {
  RootTestModule(super.cfg)
    : featureModule = FeatureModule(),
      slowPendingMiddleware = DelayedPassMiddleware();

  final FeatureModule featureModule;
  final DelayedPassMiddleware slowPendingMiddleware;

  @override
  List<Route<String, Cfg>> get routes => [
    ModuleRoute<String, Cfg>(
      path: 'feature',
      module: featureModule,
      root: LeafRoute<String, Cfg>.root(TestLeaf2()),
    ),
    LeafRoute<String, Cfg>(
      path: 'blocked',
      view: TestLeaf2(),
      middleware: [ThrowingMiddleware()],
    ),
    LeafRoute<String, Cfg>(
      path: 'rewrite',
      view: TestLeaf2(),
      middleware: [RewriteContextMiddleware()],
    ),
    LeafRoute<String, Cfg>(
      path: 'slow-pending',
      view: TestLeaf2(),
      middleware: [slowPendingMiddleware],
    ),
    ModuleRoute<String, Cfg>(path: 'module', module: featureModule),
    ModuleRoute<String, Cfg>(path: 'dependent', module: DependentModule()),
    const Route<String, Cfg>(path: 'idk'),
  ];

  @override
  FutureOr<void> dependenciesChanged() {}
  @override
  String get logTag => 'RootTestModule';
}

class Cfg {
  const Cfg(this.id);

  final String id;
}

class DependencyTrackingModule extends Module<String, Cfg> {
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
  List<Route<String, Cfg>> get routes => const [];

  @override
  String get logTag => 'DependencyTrackingModule';
}

class SlashFeatureModule extends Module<String, Cfg> {
  SlashFeatureModule(this.dependencyModule);

  final DependencyTrackingModule dependencyModule;
  int activateCalls = 0;

  @override
  List<Module<String, Cfg>> get imports => [dependencyModule];

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
  List<Route<String, Cfg>> get routes => [
    LeafRoute<String, Cfg>(path: 'child', view: TestLeaf2()),
  ];

  @override
  String get logTag => 'SlashFeatureModule';
}

class SlashRootModule extends RootModule<String, Cfg> {
  SlashRootModule(super.cfg) : dependencyModule = DependencyTrackingModule();

  final DependencyTrackingModule dependencyModule;
  late final SlashFeatureModule featureModule = SlashFeatureModule(
    dependencyModule,
  );

  @override
  List<Route<String, Cfg>> get routes => [
    ModuleRoute<String, Cfg>(
      path: '/feature',
      module: featureModule,
      root: LeafRoute<String, Cfg>.root(TestLeaf2()),
    ),
  ];

  @override
  FutureOr<void> dependenciesChanged() {}

  @override
  String get logTag => 'SlashRootModule';
}

class RepoGuardMiddleware extends Middleware<String, Cfg> {
  @override
  Future<RouteContext> call(RouteContext context) async {
    final repo = await Repo.get<GuardedRepo>();
    repo.data('guarded');
    return context;
  }

  @override
  String get logTag => 'RepoGuardMiddleware';

  @override
  String toString() => 'RepoGuardMiddleware';
}

class GuardedRepo extends Repo<String> {
  GuardedRepo(String initial) {
    data(initial);
  }

  @override
  String get logTag => 'GuardedRepo';
}

class GuardedModule extends Module<String, Cfg> {
  int initializeCalls = 0;

  @override
  void bindRepos(Bind<Repo, Cfg> bind) {
    bind((_, _) => GuardedRepo('module repo data'));
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
  List<Route<String, Cfg>> get routes => [
    LeafRoute<String, Cfg>(
      path: 'screen',
      view: TestLeaf2(),
      middleware: [RepoGuardMiddleware()],
    ),
  ];

  @override
  String get logTag => 'GuardedModule';
}

class GuardedRootModule extends RootModule<String, Cfg> {
  GuardedRootModule(super.cfg) : guardedModule = GuardedModule();

  final GuardedModule guardedModule;

  @override
  List<Module<String, Cfg>> get imports => [guardedModule];

  @override
  List<Route<String, Cfg>> get routes => [
    ModuleRoute<String, Cfg>(
      path: 'guarded',
      module: guardedModule,
      root: LeafRoute<String, Cfg>.root(TestLeaf2()),
    ),
    LeafRoute<String, Cfg>(path: 'redirect', view: TestLeaf2()),
  ];

  @override
  FutureOr<void> dependenciesChanged() {}

  @override
  String get logTag => 'GuardedRootModule';
}

class DelayedActivationModule extends Module<String, Cfg> {
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
  List<Route<String, Cfg>> get routes => [
    LeafRoute<String, Cfg>(path: 'child', view: TestLeaf2()),
  ];

  @override
  String get logTag => 'DelayedActivationModule';
}

class DelayedActivationRootModule extends RootModule<String, Cfg> {
  DelayedActivationRootModule(super.cfg)
    : delayedModule = DelayedActivationModule();

  final DelayedActivationModule delayedModule;

  @override
  List<Route<String, Cfg>> get routes => [
    ModuleRoute<String, Cfg>(
      path: 'delayed',
      module: delayedModule,
      root: LeafRoute<String, Cfg>.root(TestLeaf2()),
    ),
  ];

  @override
  FutureOr<void> dependenciesChanged() {}

  @override
  String get logTag => 'DelayedActivationRootModule';
}
