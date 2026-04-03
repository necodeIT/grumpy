import 'dart:async';

import 'package:routingkit/routingkit.dart';
import 'package:grumpy/grumpy.dart';
import 'package:rxdart/rxdart.dart';

/// [RoutingService] impementation that uses RoutingKit for route parsing and matching.
///
/// {@category routing}

class RoutingKitRoutingService<T, Config extends Object>
    extends RoutingService<T, Config>
    with LifecycleMixin {
  /// [RoutingService] impementation that uses RoutingKit for route parsing and matching.
  RoutingKitRoutingService(
    this.rootModule, {
    ModuleRegistryService<T, Config>? moduleRegistry,
    this.caseSensitive = false,
  }) : moduleRegistry = moduleRegistry ?? ModuleRegistryService<T, Config>(),
       super.internal();

  /// Centralized module lifecycle manager.
  final ModuleRegistryService<T, Config> moduleRegistry;

  Future<void> _currentNavigation = Future.value();

  RouteContext? _context;

  final Map<Uri, (Future<bool>, LeafRoute<T, Config>)> _pendingNavigations = {};

  /// The root module of the application.
  final RootModule<T, Config> rootModule;

  final List<void Function(Route<T, Config>)> _listeners = [];

  /// The underlying RoutingKit router instance.
  late final Router<Route<T, Config>> _kit;

  /// Whether route matching should be case-sensitive.
  final bool caseSensitive;
  final Map<String, Set<Module<T, Config>>> _moduleCache = {};
  final Map<Route<T, Config>, List<Route<T, Config>>> _routeLineages = {};

  final _viewChangeController = BehaviorSubject<ViewChangedEvent<T, Config>>();

  @override
  RouteContext? get currentContext => _context;

  @override
  FutureOr<void> destroy() async {
    await super.destroy();
    _listeners.clear();
    _routeLineages.clear();
    _pendingNavigations.clear();
    if (!_viewChangeController.isClosed) {
      await _viewChangeController.close();
    }
  }

  @override
  bool isActive(String path, {bool exact = true, bool ignoreParams = false}) {
    final context = _context;
    if (context == null) return false;

    final currentUri = context.uri;
    final targetUri = Uri.parse(path);

    final current = ignoreParams ? currentUri.path : currentUri.toString();
    final target = ignoreParams ? targetUri.path : targetUri.toString();

    return exact ? current == target : current.startsWith(target);
  }

  @override
  Route<T, Config> get root => rootModule.root;

  @override
  void addListener(void Function(Route<T, Config> route) listener) =>
      _listeners.add(listener);

  @override
  void removeListener(void Function(Route<T, Config> route) listener) =>
      _listeners.remove(listener);

  @override
  FutureOr<void> activate() {}

  @override
  FutureOr<void> deactivate() async {
    _context = null;
    _listeners.clear();
    _moduleCache.clear();
    _pendingNavigations.clear();
    await moduleRegistry.sync(<Module<T, Config>>[]);
  }

  @override
  FutureOr<void> dependenciesChanged() {}

  @override
  FutureOr<void> initialize() {
    _kit = createRouter(caseSensitive: caseSensitive);
    _routeLineages.clear();

    _addRoute(root, '/');

    log("Registered routes:\n${root.toTree()}");
  }

  void _addRoute(
    Route<T, Config> route,
    String parentPath, [
    List<Route<T, Config>> ancestors = const [],
  ]) {
    final fullPath = '$parentPath/${route.path}'.replaceAll('//', '/');
    final lineage = List<Route<T, Config>>.unmodifiable([...ancestors, route]);

    _routeLineages[route] = lineage;
    _kit.add(null, fullPath, route);

    if (route is ModuleRoute<T, Config>) {
      for (final child in route.module.routes) {
        _addRoute(child, fullPath, lineage);
      }
    }

    for (final child in route.children) {
      _addRoute(child, fullPath, lineage);
    }
  }

  ({LeafRoute<T, Config> leaf, List<Route<T, Config>> lineage})
  _resolveLeafRoute(Route<T, Config> matchedRoute, String path) {
    if (matchedRoute is LeafRoute<T, Config>) {
      return (
        leaf: matchedRoute,
        lineage: _routeLineages[matchedRoute] ?? [matchedRoute],
      );
    }

    if (matchedRoute is! ModuleRoute<T, Config>) {
      throw ArgumentError.value(path, 'path', 'Resolved route is not a leaf!');
    }

    final rootLeaf =
        matchedRoute.root ??
        matchedRoute.module.routes.root ??
        (throw ArgumentError.value(
          path,
          'path',
          'Resolved ModuleRoute does not have a root LeafRoute defined!',
        ));

    final lineage = <Route<T, Config>>[
      ...(_routeLineages[matchedRoute] ?? [matchedRoute]),
      rootLeaf,
    ];

    return (leaf: rootLeaf, lineage: lineage);
  }

  List<Middleware<T, Config>> _collectMiddleware(
    List<Route<T, Config>> lineage,
  ) => [for (final route in lineage) ...route.middleware];

  /// Returns a list of modules that need to be activated for the given [path].
  ///
  /// This method uses a cache to optimize repeated lookups for the same path.
  Set<Module<T, Config>> getDependencies(String path) {
    if (path.isEmpty) return {};

    if (path == '/') return {};

    if (_moduleCache.containsKey(path)) {
      return _moduleCache[path]!;
    }

    final modules = _collectModulesForPath(path);

    _moduleCache[path] = modules;

    return modules;
  }

  Set<Module<T, Config>> _collectModulesForPath(String path) {
    final modules = <Module<T, Config>>{};
    final pathSegments = _normalizePath(path);

    for (final child in root.children) {
      _collectMatchingModules(child, pathSegments, 0, modules);
    }

    return modules;
  }

  void _collectMatchingModules(
    Route<T, Config> route,
    List<String> pathSegments,
    int startIndex,
    Set<Module<T, Config>> modules,
  ) {
    final routeSegments = _normalizePath(route.path);
    if (!_matchesAt(pathSegments, startIndex, routeSegments)) return;

    final nextIndex = startIndex + routeSegments.length;

    if (route is ModuleRoute<T, Config>) {
      modules.add(route.module);
      for (final moduleChild in route.module.routes) {
        _collectMatchingModules(moduleChild, pathSegments, nextIndex, modules);
      }
    }

    for (final child in route.children) {
      _collectMatchingModules(child, pathSegments, nextIndex, modules);
    }
  }

  bool _matchesAt(
    List<String> fullPathSegments,
    int startIndex,
    List<String> routeSegments,
  ) {
    if (startIndex + routeSegments.length > fullPathSegments.length) {
      return false;
    }

    for (var i = 0; i < routeSegments.length; i++) {
      if (fullPathSegments[startIndex + i] != routeSegments[i]) {
        return false;
      }
    }

    return true;
  }

  List<String> _normalizePath(String path) {
    if (path.isEmpty || path == '/') return const [];
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse(normalized).pathSegments;
  }

  @override
  Future<void> navigate(
    String path, {
    bool skipPreview = false,
    void Function(T, bool) callback = RoutingService.noopCallback,
  }) async {
    void emitToStream(T view, bool isPreview) {
      log('View changed: isPreview=$isPreview, view=$view for path: $path');

      _viewChangeController.add((
        view: view,
        isPreview: isPreview,
        context: currentContext,
        config: RootModule.getConfig<Config>(),
      ));
    }

    void handler(T view, bool isPreview) {
      emitToStream(view, isPreview);
      callback(view, isPreview);
    }

    final uri = Uri.parse(path);

    if (uri == currentContext?.uri) {
      log(
        'Already at path: $path, skipping navigation and emitting current view.',
      );

      if (_viewChangeController.hasValue) {
        final current = _viewChangeController.value;
        callback(current.view, current.isPreview);
      }

      return;
    }

    if (_pendingNavigations.containsKey(uri)) {
      log('Navigation to $path is already in progress, forwarding callback.');

      final (future, leaf) = _pendingNavigations[uri]!;

      if (!skipPreview) {
        callback(leaf.view.preview(RouteContext.fromUri(uri)), true);
      }

      log('Waiting for pending navigation to $path to complete.');

      final success = await future;

      if (!success) {
        log(
          'Pending navigation to $path failed, not invoking content callback.',
        );
        return;
      }

      log('Pending navigation to $path completed, invoking content callback.');

      callback(await leaf.view.content(RouteContext.fromUri(uri)), false);

      return;
    }

    try {
      final cleanPath = uri.path;

      // find the route
      final match = _kit.find(null, cleanPath);

      if (match == null) {
        throw ArgumentError.value(
          path,
          'path',
          'No route found for the given path!',
        );
      }

      var matchedRoute = match.data;

      if (matchedRoute is ModuleRoute<T, Config>) {
        log(
          'Detected module route at path: $path, looking for root leaf in module ${matchedRoute.module}...',
        );

        final rootLeaf = matchedRoute.root ?? matchedRoute.module.routes.root;
        log('Found module root: $rootLeaf');
      }

      final (:leaf, :lineage) = _resolveLeafRoute(matchedRoute, path);

      final future = _navigate(uri, leaf, lineage, skipPreview, handler);

      _pendingNavigations[uri] = (future, leaf);
      _currentNavigation = future;
      await future;
    } catch (e, s) {
      log('Navigation to $path failed with error', e, s);
      rethrow;
    } finally {
      _pendingNavigations.remove(uri);
    }
  }

  Future<bool> _navigate(
    Uri uri,
    LeafRoute<T, Config> leaf,
    List<Route<T, Config>> lineage,
    bool skipPreview,
    void Function(T, bool) callback,
  ) async {
    var context = RouteContext.fromUri(uri);
    final cleanPath = uri.path;
    final middleware = _collectMiddleware(lineage);

    log('Navigating to $cleanPath with context: $context');

    if (!skipPreview) callback(leaf.view.preview(context), true);

    // activate required modules
    final dependencies = getDependencies(cleanPath);

    await moduleRegistry.sync(dependencies);

    // run middlewares (if any)
    try {
      for (var i = 0; i < middleware.length; i++) {
        final currentMiddleware = middleware[i];
        log(
          'Executing middleware ${i + 1}/${middleware.length}: ${currentMiddleware.runtimeType}',
        );
        context = await currentMiddleware(context);
      }
      log(
        'All ${middleware.length} middlewares executed successfully for $cleanPath',
      );
    } catch (e, s) {
      log(
        'A middleware threw an exception during navigation to $cleanPath',
        e,
        s,
      );
      return false;
    }

    _context = context;

    callback(await leaf.view.content(context), false);

    log('Activated route at $cleanPath');

    // notify listeners
    for (final listener in _listeners) {
      listener(leaf);
    }

    return true;
  }

  @override
  String get logTag => 'RoutingKitRoutingService';

  @override
  StreamSubscription<ViewChangedEvent<T, Config>> onViewChanged(
    void Function(ViewChangedEvent<T, Config>) callback,
  ) => _viewChangeController.stream.listen(callback);

  @override
  Stream<ViewChangedEvent<T, Config>> get viewStream =>
      _viewChangeController.stream;

  @override
  Future<void> get currentNavigation => _currentNavigation;
}
