import 'dart:typed_data';

import 'package:grumpy/grumpy.dart';

/// Codec for encoding and decoding integers to and from byte arrays.
///
/// Converts `int` values to little-endian 64-bit byte arrays and back.
///
/// Some storage layers need a compact binary representation for integer payloads.
///
/// [encode] writes the integer into an 8-byte [ByteData] buffer and [decode]
/// reads it back as little-endian `int64`.
///
/// Values are encoded as signed 64-bit integers.
///
/// - Runtime type: `int`.
/// - Serialized type: [Uint8List].
///
/// For example:
/// ```dart
/// const codec = IntegerCodec();
/// ```
class IntegerCodec extends SerializationCodec<int, Uint8List> {
  /// Codec for encoding and decoding integers to and from byte arrays.
  const IntegerCodec();

  @override
  Uint8List encode(int value) {
    final bytes = ByteData(8)..setInt64(0, value, Endian.little);
    return bytes.buffer.asUint8List();
  }

  @override
  int decode(Uint8List encoded) {
    final bytes = ByteData.sublistView(encoded);
    return bytes.getInt64(0, Endian.little);
  }
}
