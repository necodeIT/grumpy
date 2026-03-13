import 'dart:convert';
import 'dart:typed_data';

import 'package:grumpy/grumpy.dart';

/// UTF-8 codec for plain text payloads.
class StringUtf8Codec implements SerializationCodec<String, Uint8List> {
  /// Creates a string codec.
  const StringUtf8Codec();

  @override
  Uint8List encode(String value) => Uint8List.fromList(utf8.encode(value));

  @override
  String decode(Uint8List payload) => utf8.decode(payload);
}
