import 'package:grumpy/grumpy.dart';

class StringCodec implements SerializationCodec<String, String> {
  const StringCodec();

  @override
  String decode(String payload) => payload;

  @override
  String encode(String value) => value;
}
