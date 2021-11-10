import 'package:flutter_test/flutter_test.dart';
import 'package:tuple/tuple.dart';
import 'package:weechat/relay/completion.dart';

void main() {
  group('Byte offset calculations', () {
    test('Byte offsets', _byteOffsets);
    test('Text positions', _textPositions);
  });
  group('Completions', () {
    test('Invalid completions', _invalidCompletions);
    test('Valid completions', _validCompletions);
  });
}

void _invalidCompletions() {}

void _validCompletions() {
  final c01 = RelayCompletion(
    text: 'a',
    addSpace: false,
    baseWord: 'a',
    context: 'auto',
    list: ['asd'],
    posStart: 0,
    posEnd: 1,
  );

  expect(c01.next(), equals(Tuple2('asd', 3)));

  final c02 = RelayCompletion(
    text: 'a',
    addSpace: true,
    baseWord: 'a',
    context: 'auto',
    list: ['asd'],
    posStart: 0,
    posEnd: 1,
  );

  expect(c02.next(), equals(Tuple2('asd ', 4)));
}

void _byteOffsets() {
  // ascii text with no additional bytes
  expect(RelayCompletion.byteOffset('123', 0), equals(0));
  expect(RelayCompletion.byteOffset('123', 1), equals(1));
  expect(RelayCompletion.byteOffset('123', 2), equals(2));

  // some utf8 characters
  expect(RelayCompletion.byteOffset('äöü', 0), equals(0));
  expect(RelayCompletion.byteOffset('äöü', 1), equals(2));
  expect(RelayCompletion.byteOffset('äöü', 2), equals(4));
}

void _textPositions() {
  // ascii text with no additional bytes
  expect(RelayCompletion.textPosition('123', 0), equals(0));
  expect(RelayCompletion.textPosition('123', 1), equals(1));
  expect(RelayCompletion.textPosition('123', 2), equals(2));

  // some utf8 characters
  expect(RelayCompletion.textPosition('äöü', 0), equals(0));
  expect(RelayCompletion.textPosition('äöü', 2), equals(1));
  expect(RelayCompletion.textPosition('äöü', 4), equals(2));
}
