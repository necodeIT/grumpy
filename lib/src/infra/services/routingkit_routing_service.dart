import 'dart:async';

import 'package:routingkit/routingkit.dart';
import 'package:modular_foundation/modular_foundation.dart';

/// [RoutingService] impementation that uses RoutingKit for route parsing and matching.
class RoutingKitRoutingService<T, Config extends Object>
    extends RoutingService<T, Config>
    with LifecycleMixin {
  RouteContext? _context;

  /// The root module of the application.
  final RootModule<Config, T> rootModule;

  final List<void Function(Route<T, Config>)> _listeners = [];

  /// The underlying RoutingKit router instance.
  late final Router<Route<T, Config>> _kit;

  /// Whether route matching should be case-sensitive.
  final bool caseSensitive;
  final Map<String, List<Module<Config, T>>> _moduleCache = {};

  /// [RoutingService] impementation that uses RoutingKit for route parsing and matching.
  RoutingKitRoutingService(this.rootModule, {this.caseSensitive = false}) {
    initialize();
  }

  @override
  RouteContext currentContext() => _context!;

  @override
  FutureOr<void> dispose() {
    super.dispose();
    _listeners.clear();
  }

  @override
  bool isActive(String path, {bool exact = true, bool ignoreParams = false}) {
    throw UnimplementedError();
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
  FutureOr<void> deactivate() {}

  @override
  FutureOr<void> dependenciesChanged() {}

  @override
  FutureOr<void> initialize() {
    _kit = createRouter(caseSensitive: caseSensitive);

    // TODO: handle top level child routes
    _addRoute(root, '/');
  }

  void _addRoute(Route<T, Config> route, String parentPath) {
    final fullPath = '$parentPath/${route.path}'.replaceAll('//', '/');

    _kit.add(null, fullPath, route);

    if (route is ModuleRoute<T, Config>) {
      for (final child in route.module.routes) {
        _addRoute(child, fullPath);
      }
    }

    for (final child in route.children) {
      _addRoute(child, fullPath);
    }
  }

  /// Returns a list of modules that need to be activated for the given [path].
  ///
  /// This method uses a cache to optimize repeated lookups for the same path.
  List<Module<Config, T>> getDependencies(String path) {
    if (path.isEmpty) return [];

    if (path == '/') return [];

    if (_moduleCache.containsKey(path)) {
      return _moduleCache[path]!;
    }

    final List<Module<Config, T>> modules = [];
    final List<String> pathNodes = path.split('/');

    String currentPath = "";
    for (String pathNode in pathNodes) {
      currentPath += "/$pathNode";
      final match = _kit.find(null, currentPath)?.data;
      if (match is ModuleRoute<T, Config>) {
        modules.add(match.module);
      }
    }

    _moduleCache[path] = modules;

    return modules;
  }

  @override
  Future<void> navigate(
    String path, {
    bool skipPreview = false,
    required Function(T) callback,
  }) async {
    final uri = Uri.parse(path);
    final cleanPath = uri.path;

    // find the route
    final match = _kit.find(null, cleanPath);

    if (match == null) {
      throw ArgumentError.value(
        path,
        "path",
        "No route found for the given path!",
      );
    }

    final leaf = match.data;

    // check if leaf (throw if not)
    if (leaf is! LeafRoute) {
      throw ArgumentError.value(path, "path", "Resolved route is not a leaf!");
    }

    leaf as LeafRoute<T, Config>;

    // find context
    var context = RouteContext(
      fullPath: path,
      pathParams: match.params,
      queryParams: uri.queryParameters,
      queryParamsAll: uri.queryParametersAll,
      fragment: uri.fragment,
    );

    log('Navigating to $path with context: $context');

    if (!skipPreview) callback(leaf.view.preview(context));

    // activate required modules
    final dependencies = getDependencies(cleanPath);

    for (Module<Config, T> module in dependencies) {
      module.activate();
      log('Activated module: ${module.runtimeType}');
    }

    // run middlewares (if any)
    try {
      for (final middleware in leaf.middleware) {
        context = await middleware(context);
        log('Middleware processed context: $context');
      }
    } catch (e, s) {
      log('A middleware threw an exception during navigation to $path', e, s);
      rethrow;
    }

    _context = context;

    callback(await leaf.view.build(context));

    log('Activated route at $path');

    // notify listeners
    for (final listener in _listeners) {
      listener(leaf);
    }
  }
}
