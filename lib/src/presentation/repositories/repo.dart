import 'package:get_it/get_it.dart' hide Disposable;
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:modular_foundation/modular_foundation.dart';
import 'package:rxdart/rxdart.dart';

/// A repository that manages the state of data of type [T].
/// It's purpose is to expose the data in a presentable way by providing
/// filter, sorting, and CRUD operations that can be easily bound by consumers.
///
/// See [RepoState] for more details on the possible states.
abstract class Repo<T>
    with LogMixin, LifecycleMixin, LifecycleHooksMixin, Disposable {
  final _stream = BehaviorSubject.seeded(RepoState<T>.loading());

  /// Creates a new instance of [Repo].
  Repo() {
    onDisposed(_stream.close);
  }

  /// Shorthand to get a registered instance from GetIt.
  @nonVirtual
  Clazz get<Clazz extends Object>() => GetIt.I<Clazz>();

  @nonVirtual
  @override
  String get group => 'Repo';

  /// The current state of this repository.
  RepoState<T> get state => _stream.value;

  /// A stream of [RepoState] updates.
  ValueStream<RepoState<T>> get stream => _stream.stream;

  /// Emits a new data state with the given [value].
  void data(T value) {
    _stream.add(RepoState.data(value));
  }

  /// Emits a new loading state.
  void loading() {
    _stream.add(RepoState.loading());
  }

  /// Emits a new error state with the given [error] and optional [stackTrace].
  void error(Object error, [StackTrace? stackTrace]) {
    _stream.add(RepoState.error(error, stackTrace));
  }

  @nonVirtual
  @override
  Level get logLevel => Level.INFO;

  @nonVirtual
  @override
  Level get errorLogLevel => Level.SEVERE;
}
