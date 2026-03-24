import 'package:grumpy/grumpy.dart';

/// Durable repo snapshot storage service.
///
/// Defines the storage API for loading, saving, and deleting repo snapshots.
///
/// Repos should depend on a persistence contract, not on one storage backend.
///
/// Implementations map [StorageKey] identities to persisted [RepoSnapshot]
/// payloads using the provided [SerializationCodec].
///
/// Missing snapshots should return `null` rather than throwing.
///
/// - `T`: the runtime repo data type.
/// - `Serialized`: the persisted payload type.
/// - [key], [codec]: the storage identity and serialization boundary.
///
/// For example:
/// ```dart
/// final persistence = RepoStatePersistenceService();
/// ```
///
/// {@category persistence}

abstract class RepoStatePersistenceService extends Service {
  /// Returns the DI-registered persistence service.
  factory RepoStatePersistenceService() =>
      Service.get<RepoStatePersistenceService>();

  /// Internal constructor for concrete persistence implementations.
  RepoStatePersistenceService.internal();

  /// Loads a snapshot for [key], returning `null` on miss.
  Future<RepoSnapshot<T>?> load<T, Serialized extends Object>(
    StorageKey key, {
    required SerializationCodec<T, Serialized> codec,
  });

  /// Saves [snapshot] for [key].
  Future<void> save<T, Serialized extends Object>(
    StorageKey key,
    RepoSnapshot<T> snapshot, {
    required SerializationCodec<T, Serialized> codec,
  });

  /// Deletes a snapshot by [key].
  Future<void> delete(StorageKey key);

  /// Clears all snapshots in [namespace].
  Future<void> clearNamespace(String namespace);

  @override
  bool get singelton => true;

  @override
  String get group => '${super.group}.RepoStatePersistenceService';
}
