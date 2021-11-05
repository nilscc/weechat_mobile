import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:weechat/relay/protocol/parser.dart';

import 'parser_data.dart';

void main() {
  group('RelayParser', () {
    test('Head', () {
      final p = RelayParser(Uint8List.fromList(TEST_DATA));
      expect(p.length(), equals(155));
      expect(p.compressed(), isTrue);
    });
    test('Body', () {
      final p = RelayParser(Uint8List.fromList(TEST_DATA));
      expect(p.body().buffer.asUint8List(),
          equals(Uint8List.fromList(DECOMP_DATA)));
    });
  });
}
