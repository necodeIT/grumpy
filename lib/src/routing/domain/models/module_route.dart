import 'package:grumpy/grumpy.dart';

/// A route that activates a [Module] when matched.
///
/// Declares a route boundary that mounts and activates a module graph.
///
/// Feature-level navigation often needs more than a view; it needs scoped DI
/// and lifecycle-managed dependencies.
///
/// [ModuleRoute] extends [Route] with a target [module] and optional module
/// [root] view.
///
/// Use [root] when navigating to the module path should immediately render a
/// default leaf.
///
/// - `T`: the presentation type.
/// - `Config`: the module configuration type.
/// - [module], [root], [middleware]: module-routing behavior.
///
/// For example:
/// ```dart
/// ModuleRoute<Object, AppConfig>(
///   path: '/settings',
///   module: SettingsModule(),
/// );
/// ```
///
/// {@category routing}

class ModuleRoute<T, Config extends Object> extends Route<T, Config> {
  /// Creates a [ModuleRoute] for the given [path] and [module].
  ///
  /// Optional [middleware] can be used to protect access to the module.
  const ModuleRoute({
    required super.path,
    required this.module,
    super.middleware,
    this.root,
  });

  /// The module that will be mounted when this route is activated.
  final Module<T, Config> module;

  /// The root [LeafRoute] of the module, if any.
  ///
  /// If not null, this [LeafRoute] will be used as the entry point
  /// when navigating to this [ModuleRoute].
  final LeafRoute<T, Config>? root;

  @override
  String toString() {
    return 'ModuleRoute(path: $path, module: $module, middleware: $middleware, root: $root)';
  }

  @override
  List<String> get treeInfo => [
    'module: ${module.logTag.replaceAll('Module', '')}',
    if (root != null && root?.path != '/') 'root: ${root!.path}',
    ...super.treeInfo,
    if (module.routes.where((r) => r.path != '/').isNotEmpty)
      'subroutes: ${module.routes.length}',
  ];
}
