import 'dart:typed_data';

import 'package:grumpy/grumpy.dart';

/// Codec for encoding and decoding integers to and from byte arrays.
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
