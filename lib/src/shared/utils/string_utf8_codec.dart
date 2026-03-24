import 'dart:convert';
import 'dart:typed_data';

import 'package:grumpy/grumpy.dart';

/// UTF-8 codec for plain text payloads.
///
/// Converts a [String] to and from UTF-8 bytes.
///
/// Text payloads are common enough in cache and persistence code to justify a
/// ready-made codec.
///
/// [encode] uses `utf8.encode`, and [decode] uses `utf8.decode`.
///
/// Decoding invalid UTF-8 will throw.
///
/// - Runtime type: [String].
/// - Serialized type: [Uint8List].
///
/// For example:
/// ```dart
/// const codec = StringUtf8Codec();
/// ```
class StringUtf8Codec implements SerializationCodec<String, Uint8List> {
  /// Creates a string codec.
  const StringUtf8Codec();

  @override
  Uint8List encode(String value) => Uint8List.fromList(utf8.encode(value));

  @override
  String decode(Uint8List payload) => utf8.decode(payload);
}
