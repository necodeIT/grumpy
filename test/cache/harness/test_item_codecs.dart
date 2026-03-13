import 'dart:typed_data';

import 'package:grumpy/grumpy.dart';

import 'query_mixins_test_harness.dart';

class TestItemCodec extends SerializationCodec<TestItem, Uint8List> {
  const TestItemCodec();
  @override
  TestItem decode(Uint8List payload) {
    // does not get called in the test suite, so can be left unimplemented
    throw UnimplementedError();
  }

  @override
  Uint8List encode(TestItem value) {
    // does not get called in the test suite, so can be left unimplemented
    throw UnimplementedError();
  }
}

class TestItemListCodec extends SerializationCodec<List<TestItem>, Uint8List> {
  const TestItemListCodec();
  @override
  List<TestItem> decode(Uint8List payload) {
    // does not get called in the test suite, so can be left unimplemented
    throw UnimplementedError();
  }

  @override
  Uint8List encode(List<TestItem> value) {
    // does not get called in the test suite, so can be left unimplemented
    throw UnimplementedError();
  }
}
