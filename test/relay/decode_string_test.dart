import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:weechat/relay/decode_string.dart';

void main() {
  group('Decoder', () {
    test('Decode "handshake"', _handshake);
    test('String length', _stringLength);
    test('Encode strings', _encodeString);
  });
}

void _stringLength() {
  expect(stringLength(ByteData.sublistView(Uint8List.fromList([0x00, 0x00, 0x00, 0x00]))), equals(0));
  expect(stringLength(ByteData.sublistView(Uint8List.fromList([0x00, 0x00, 0x00, 0x01]))), equals(1));
  expect(stringLength(ByteData.sublistView(Uint8List.fromList([0x00, 0x00, 0x00, 0xFF]))), equals(255));
  expect(stringLength(ByteData.sublistView(Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF]))), equals(-1));
}

void _handshake() {
  final data = ByteData.sublistView(Uint8List.fromList([
    0,
    0,
    0,
    9,
    104,
    97,
    110,
    100,
    115,
    104,
    97,
    107,
    101,
  ]));

  expect(decodeString(data), equals('handshake'));
}

void _encodeString() {
  final data = [
    0,
    0,
    0,
    9,
    104,
    97,
    110,
    100,
    115,
    104,
    97,
    107,
    101,
  ];
  expect(encodeString('handshake'), equals(data));
}