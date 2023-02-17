import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weechat/relay/colors.dart';
import 'package:weechat/relay/colors/color_codes.dart';
import 'package:weechat/relay/colors/extended_definition.dart';

void main() {
  group('stripColors', () {
    for (int i = 0; i < _cols01.length; ++i) {
      test('stripColors(#$i)', () {
        _stripColors(i);
      });
    }
  });

  test('parseColors', _parseColors);
  test('parseColorsExtended', _parseColorsExtended);
}

const _defaultColor = Colors.black;

final _cols01 = [
  '\x1901',
  //'\x19@00001', invalid => no color option
  '\x19F*05',
  '\x19F@00214',
  '\x19B05',
  '\x19B@00124',
  '\x19*05',
  '\x19*@00214',
  '\x19*08,05',
  '\x19*01,@00214',
  '\x19*@00214,05',
  '\x19*@00214,@00017',
  '\x19*08~05',
  '\x19*01~@00214',
  '\x19*@00214~05',
  '\x19*@00214~@00017',
  '\x1A*',
  '\x1A_',
  '\x1A|',
  '\x1B!',
  '\x1C',
];

void _stripColors(int idx) {
  final testString = "${_cols01[idx]}test";
  const expected = "test";

  // ignore: avoid_print
  print('Input: $testString (expected: $expected)');

  expect(stripColors(testString), equals(expected));
}

void _parseColors() {
  final rt01 = parseColors('\x19F00\x19F01test', _defaultColor);
  expect(rt01.text.toPlainText(), equals('test'));
  expect(rt01.text.style?.color, equals(defaultColorCodes[1]));

  final rt02 = parseColors('\x19F00~\x19F@00151f0ck', _defaultColor);
  expect(rt02.text.toPlainText(), equals('~f0ck'));

  final rt03 = parseColors('\x1A*\x19F|01bla', _defaultColor);
  expect(rt03.text.toPlainText(), equals('bla'));
  expect(rt03.text.style?.fontWeight, equals(FontWeight.bold));
  expect(rt03.text.style?.color, equals(defaultColorCodes[1]));

  final rt04 = parseColors('\x1A\x01\x19F|05test', _defaultColor);
  expect(rt04.text.toPlainText(), equals('test'));
  expect(rt04.text.style?.fontWeight, equals(FontWeight.bold));
  expect(rt04.text.style?.color, equals(defaultColorCodes[5]));

  final rt05 = parseColors('\x19F@*00001test', _defaultColor);
  expect(rt05.text.toPlainText(), equals('test'));
  expect(rt05.text.style?.fontWeight, equals(FontWeight.bold));
  expect(rt05.text.style?.color, equals(getExtendedColor(1)));
}

void _parseColorsExtended() {
  final rt01 = parseColors('\x19F00\x19F01test', _defaultColor);
  expect(rt01.text.toPlainText(), equals('test'));
  expect(rt01.text.style?.color, equals(defaultColorCodes[1]));
}
