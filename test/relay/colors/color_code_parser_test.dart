import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuple/tuple.dart';
import 'package:weechat/relay/colors/color_code_parser.dart';
import 'package:weechat/relay/colors/color_codes.dart';

void main() {
  group('tryParseAttribute', () {
    for (final inp in _tryParseAttributeInputs.keys) {
      final exp = _tryParseAttributeInputs[inp];
      test('tryParseAttribute($inp, $exp)', () => _tryParseAttribute(inp, exp));
    }
  });
  group('tryParseColor', () {
    for (final inp in _tryParseColorInputs.keys) {
      final exp = _tryParseColorInputs[inp];
      test('tryParseColor($inp, $exp)', () => _tryParseColor(inp, exp));
    }
  });

  group('ColorCodeParser', () {
    for (final inp in _colorCodeParserInputs.keys) {
      final exp = _colorCodeParserInputs[inp];
      test('.parse($inp, $exp)', () => _colorCodeParser01(inp, exp));
    }
  });
}

final _tryParseAttributeInputs = {
  // empty input
  '': null,
  // invalid input
  'aksjdh': null,

  // correct input
  '*': RelayAttribute(bold: true),
  '/': RelayAttribute(italic: true),
  '_': RelayAttribute(underline: true),
  '|': RelayAttribute(keepAttributes: true),
  '!': RelayAttribute(reverse: true),
};

void _tryParseAttribute(String input, RelayAttribute? expected) {
  final it = input.runes.iterator;
  it.moveNext();

  RelayAttribute? ts = tryParseAttribute(it);
  expect(ts, equals(expected));
}

final _defaultColor = Colors.black;

final _tryParseColorInputs = {
  '': null,
  '0': null,
  '00': _defaultColor,
  '01': colorCodes[1],
  '02': colorCodes[2],
  '03': colorCodes[3],
  '04': colorCodes[4],
  '05': colorCodes[5],
  '99': null,
  '@00000': Colors.black,
  '@00214': Color.fromARGB(0xFF, 255, 175, 0),
  '@00255': Color.fromARGB(0xFF, 238, 238, 238),
  '@00256': null,
  '@12345': null,
  '@asd': null,
  '@': null,
};

void _tryParseColor(String input, Color? expected) {
  final it = input.runes.iterator;
  it.moveNext();

  Color? c = tryParseColor(it, _defaultColor);
  expect(c, equals(expected));

  if (c == null)
    expect(it.rawIndex, equals(-1));
  else
    expect(it.rawIndex, equals(input.length - 1));
}

final _std01 = colorCodes[1], _ext214 = Color.fromARGB(0xFF, 255, 175, 0);

final _tsBold = TextStyle(fontWeight: FontWeight.bold);

final _colorCodeParserInputs = {
  // 0x19 + STD
  '\x1900': Tuple3(_defaultColor, null, null),
  '\x1901': Tuple3(_std01, null, null),

  // 0x19 + EXT
  '\x19@00214': Tuple3(_ext214, null, null),

  // 0x19 + F + (A)STD
  '\x19F*01': Tuple3(_std01, _tsBold, null),

  // 0x19 + F + (A)EXT
  '\x19F*@00214': Tuple3(_ext214, _tsBold, null),

  // 0x19 + B + STD
  '\x19B01': Tuple3(null, null, _std01),

  // 0x19 + B + EXT
  '\x19B@00214': Tuple3(null, null, _ext214),

  // 0x19 + * + (A)STD
  '\x19**01': Tuple3(_std01, _tsBold, null),

  // 0x19 + * + (A)EXT
  '\x19**@00214': Tuple3(_ext214, _tsBold, null),

  // 0x19 + * + (A)STD + ',' + STD
  '\x19**01,01': Tuple3(_std01, _tsBold, _std01),
  // 0x19 + * + (A)STD + ',' + EXT
  '\x19**01,@00214': Tuple3(_std01, _tsBold, _ext214),
  // 0x19 + * + (A)EXT + ',' + STD
  '\x19**@00214,01': Tuple3(_ext214, _tsBold, _std01),
  // 0x19 + * + (A)EXT + ',' + EXT
  '\x19**@00214,@00214': Tuple3(_ext214, _tsBold, _ext214),

  // 0x19 + * + (A)STD + '~' + STD
  '\x19**01~01': Tuple3(_std01, _tsBold, _std01),
  // 0x19 + * + (A)STD + '~' + EXT
  '\x19**01~@00214': Tuple3(_std01, _tsBold, _ext214),
  // 0x19 + * + (A)EXT + '~' + STD
  '\x19**@00214~01': Tuple3(_ext214, _tsBold, _std01),
  // 0x19 + * + (A)EXT + '~' + EXT
  '\x19**@00214~@00214': Tuple3(_ext214, _tsBold, _ext214),
};

void _colorCodeParser01(
    String input, Tuple3<Color?, TextStyle?, Color?>? expected) {

  final it = input.runes.iterator;

  assert(it.moveNext() && it.rawIndex == 0);

  final c = ColorCodeParser(defaultFgColor: _defaultColor);
  c.parse(it);

  if (expected != null) {
    expect(c.fgColor, equals(expected.item1));
    expect(c.fgTextStyle, equals(expected.item2));
    expect(c.bgColor, equals(expected.item3));

    expect(it.rawIndex, equals(input.length - 1));
  }
  else {
    expect(c.fgColor, equals(null));
    expect(c.fgTextStyle, equals(null));
    expect(c.bgColor, equals(null));

    expect(it.rawIndex, equals(0));
  }
}
