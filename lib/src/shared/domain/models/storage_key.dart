/// Stable storage key contract shared by cache and snapshot persistence layers.
abstract class StorageKey {
  /// Logical namespace partition.
  String get namespace;

  /// Stable identifier inside [namespace].
  String get primaryKey;

  /// Serialized-shape fingerprint.
  String get schemaId;

  /// Optional manual compatibility version.
  int? get compatVersion;

  /// Stable persisted representation.
  String asStorageKey();
}
