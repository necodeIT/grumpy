import 'dart:async';

import 'package:routingkit/routingkit.dart';
import 'package:grumpy/grumpy.dart';

/// [RoutingService] impementation that uses RoutingKit for route parsing and matching.
class RoutingKitRoutingService<T, Config extends Object>
    extends RoutingService<T, Config>
    with LifecycleMixin {
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

  /// [RoutingService] impementation that uses RoutingKit for route parsing and matching.
  RoutingKitRoutingService(this.rootModule, {this.caseSensitive = false}) {
    initialize();
  }

  @override
  RouteContext? get currentContext => _context;

  @override
  FutureOr<void> free() {
    super.free();
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
  Set<Module<T, Config>> getDependencies(String path) {
    if (path.isEmpty) return {};

    if (path == '/') return {};

    if (_moduleCache.containsKey(path)) {
      return _moduleCache[path]!;
    }

    final Set<Module<T, Config>> modules = {};
    final List<String> pathNodes = path.split('/');

    String currentPath = '';
    for (String pathNode in pathNodes) {
      currentPath += '/$pathNode';
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
    required void Function(T, bool) callback,
  }) async {
    final uri = Uri.parse(path);

    if (uri == currentContext?.uri) {
      log('Already at path: $path, skipping navigation.');

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

      var leaf = match.data;

      if (leaf is ModuleRoute<T, Config>) {
        leaf =
            leaf.root ??
            (throw ArgumentError.value(
              path,
              'path',
              'Resolved ModuleRoute does not have a root LeafRoute defined!',
            ));
      }

      // check if leaf (throw if not)
      if (leaf is! LeafRoute) {
        throw ArgumentError.value(
          path,
          'path',
          'Resolved route is not a leaf!',
        );
      }

      leaf as LeafRoute<T, Config>;

      final future = _navigate(uri, leaf, skipPreview, callback);

      _pendingNavigations[uri] = (future, leaf);
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
    bool skipPreview,
    void Function(T, bool) callback,
  ) async {
    var context = RouteContext.fromUri(uri);
    final cleanPath = uri.path;

    log('Navigating to $cleanPath with context: $context');

    if (!skipPreview) callback(leaf.view.preview(context), true);

    // activate required modules
    final dependencies = getDependencies(cleanPath);

    for (Module<T, Config> module in dependencies) {
      await module.activate();
      log('Activated module: ${module.runtimeType}');
    }

    // run middlewares (if any)
    try {
      for (var i = 0; i < leaf.middleware.length; i++) {
        final middleware = leaf.middleware[i];
        log(
          'Executing middleware ${i + 1}/${leaf.middleware.length}: ${middleware.runtimeType}',
        );
        context = await middleware(context);
      }
      log(
        'All ${leaf.middleware.length} middlewares executed successfully for $cleanPath',
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
}
