/// JSON-like payload map.
///
/// Provides a standard alias for map-shaped serialized payloads.
///
/// Many codecs operate on JSON-shaped maps and this alias keeps those
/// signatures readable.
///
/// [JsonMap] is simply `Map<String, Object?>`.
///
/// This is a payload alias, not a guarantee that values are fully JSON-safe.
///
/// For example:
/// ```dart
/// JsonMap payload = {'id': 1, 'name': 'Ada'};
/// ```
///
/// {@category shared}
typedef JsonMap = Map<String, Object?>;

/// Converts between runtime data and serialized wire payload.
///
/// Encodes runtime values into a storage or wire representation and decodes
/// them back again.
///
/// Cache and persistence layers should not need to know how domain objects are
/// serialized.
///
/// Implementations provide [encode] and [decode], or can be created inline with
/// [SerializationCodec.call].
///
/// Keep codecs backward compatible when persisted payloads may survive upgrades.
///
/// - `Data`: the runtime type used by application code.
/// - `Serialized`: the storage or wire format.
///
/// For example:
/// ```dart
/// const userCodec = SerializationCodec<User, JsonMap>.call(
///   encode: (user) => user.toJson(),
///   decode: User.fromJson,
/// );
/// ```
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
