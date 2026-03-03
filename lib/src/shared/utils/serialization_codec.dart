/// JSON-like payload map.
///
/// {@category shared}

typedef JsonMap = Map<String, Object?>;

/// Converts between runtime data and serialized wire payload.
///
/// {@category shared}

abstract class SerializationCodec<Data, Serialized extends Object> {
  /// Converts between runtime data and serialized wire payload.
  const SerializationCodec();

  /// Simple codec implementation using provided encode/decode callbacks.
  ///
  /// Useful for quick ad-hoc codec creation without needing a full class implementation.
  const factory SerializationCodec.call({
    required Serialized Function(Data) encode,
    required Data Function(Serialized) decode,
  }) = _CallBackSerializationCodec;

  /// Serializes runtime data into storage/wire payload.
  Serialized encode(Data value);

  /// Deserializes storage/wire payload into runtime data.
  Data decode(Serialized payload);
}

class _CallBackSerializationCodec<Data, Serialized extends Object>
    implements SerializationCodec<Data, Serialized> {
  /// Creates a codec from encode/decode callbacks.
  const _CallBackSerializationCodec({
    required Serialized Function(Data) encode,
    required Data Function(Serialized) decode,
  }) : _encode = encode,
       _decode = decode;
  final Serialized Function(Data) _encode;
  final Data Function(Serialized) _decode;

  @override
  Serialized encode(Data value) => _encode(value);

  @override
  Data decode(Serialized payload) => _decode(payload);
}
