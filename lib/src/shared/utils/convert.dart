import 'dart:convert';
import 'dart:typed_data';

/// Utility class for converting values to Base64, UTF-8 bytes, and strings.
///
/// Defines a small conversion interface used by the string and byte helpers.
///
/// Common encoding conversions appear in storage and transport code often
/// enough to justify one shared helper.
///
/// Concrete converters implement [toBase64], [toUtf8Bytes], and
/// [toUtf8String].
///
/// This is convenience API, not a replacement for `dart:convert`.
///
/// - `T`: the wrapped source value type.
///
/// For example:
/// ```dart
/// final bytes = 'hello'.convert.toUtf8Bytes();
/// ```
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

/// Extension to add the `convert` getter to [String].
///
/// Exposes conversion helpers directly from a string value.
///
/// String-to-bytes and string-to-base64 conversions are common in codec and
/// storage code.
///
/// The [convert] getter returns a [Converter<String>] backed by
/// [_StringConverter].
///
/// `toBase64()` encodes the string as UTF-8 first.
///
/// The receiver string itself is the only input.
///
/// For example:
/// ```dart
/// final encoded = 'hello'.convert.toBase64();
/// ```
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

/// Extension to add the `convert` getter to [Uint8List].
///
/// Exposes conversion helpers directly from a byte array.
///
/// Cache and persistence code often needs fast access to byte-to-string and
/// byte-to-base64 conversions.
///
/// The [convert] getter returns a [Converter<Uint8List>] backed by
/// [_BytesConverter].
///
/// `toUtf8String()` assumes the bytes are valid UTF-8.
///
/// The receiver byte list itself is the only input.
///
/// For example:
/// ```dart
/// final text = bytes.convert.toUtf8String();
/// ```
///
/// {@category shared}

extension BytesX on Uint8List {
  /// Converter for this byte array, providing utility methods for encoding to Base64 and strings.
  Converter<Uint8List> get convert => _BytesConverter(this);
}
