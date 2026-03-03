import 'dart:convert';
import 'dart:typed_data';

/// Utility class for converting strings to Base64 and UTF-8 bytes.
///
/// {@category shared}

abstract class Converter<T> {
  /// Creates a [Converter] for the given string value.
  const Converter(this.value);

  /// The underlying value to be converted.
  final T value;

  /// Converts this to a Base64-encoded string.
  String toBase64();

  /// Converts this to UTF-8 encoded bytes.
  Uint8List toUtf8Bytes();

  /// Converts this to a UTF-8 string.
  String toUtf8String();
}

class _StringConverter extends Converter<String> {
  const _StringConverter(super.value);

  @override
  String toBase64() => base64Encode(toUtf8Bytes());

  @override
  Uint8List toUtf8Bytes() => utf8.encode(value);

  @override
  String toUtf8String() => value;
}

/// Extension to add the `convert` getter to String, allowing easy byte and base64 conversions.
///
/// {@category shared}

extension StringX on String {
  /// Converter for this string, providing utility methods for encoding to Base64 and bytes.
  Converter<String> get convert => _StringConverter(this);
}

class _BytesConverter extends Converter<Uint8List> {
  const _BytesConverter(super.value);

  @override
  String toBase64() => base64Encode(value);

  @override
  Uint8List toUtf8Bytes() => value;

  @override
  String toUtf8String() => utf8.decode(value);
}

/// Extension to add the `convert` getter to Uint8List, allowing easy byte and base64 conversions.
///
/// {@category shared}

extension BytesX on Uint8List {
  /// Converter for this byte array, providing utility methods for encoding to Base64 and strings.
  Converter<Uint8List> get convert => _BytesConverter(this);
}
