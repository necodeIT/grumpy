/// JSON-like payload map.
typedef JsonMap = Map<String, Object?>;

/// Converts between runtime data and serialized wire payload.
abstract class SerializationCodec<Data, Serialized extends Object> {
  /// Serializes runtime data into storage/wire payload.
  Serialized encode(Data value);

  /// Deserializes storage/wire payload into runtime data.
  Data decode(Serialized payload);
}
