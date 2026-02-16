import 'package:grumpy/grumpy.dart';

/// A route that activates a [Module] when matched.
///
/// Use [ModuleRoute] for feature- or domain-level entry points that should
/// mount a dedicated [Module] (and its dependency graph) on navigation.
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
}
