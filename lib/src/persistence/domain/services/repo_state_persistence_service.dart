import 'package:grumpy/grumpy.dart';

/// Durable repo snapshot storage service.
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
