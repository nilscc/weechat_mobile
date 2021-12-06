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

  group('tryParseColorOptions', () {
    for (final inp in _tryParseColorOptionInputs.keys) {
      final exp = _tryParseColorOptionInputs[inp];
      test('tryParseColorOptions($inp, $exp)',
          () => _tryParseColorOptions(inp, exp));
    }
  });

  group('ColorCodeParser', () {
    for (final inp in _colorCodeParserInputs.keys) {
      final exp = _colorCodeParserInputs[inp];
      test('.parse($inp, $exp)', () => _colorCodeParser01(inp, exp));
    }
  });
}

final _std01 = colorCodes[1],
    _ext214 = Color.fromARGB(0xFF, 255, 175, 0),
    _opt01 = colorOptions[1] ?? _defaultColor,
    _opt30 = colorOptions[30] ?? _defaultColor,
    _opt40 = colorOptions[40] ?? _defaultColor;

final _tsBold = TextStyle(fontWeight: FontWeight.bold);

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

  // alternative input (used by 0x1A command)
  '\x01': RelayAttribute(bold: true),
  '\x03': RelayAttribute(italic: true),
  '\x04': RelayAttribute(underline: true),
  '\x02': RelayAttribute(reverse: true),
};

void _tryParseAttribute(String input, RelayAttribute? expected) {
  final it = input.runes.iterator;
  RelayAttribute? ts = tryParseAttribute(it);
  expect(ts, equals(expected));
}

final _defaultColor = Colors.black;

/*
 * COLOR CODE OPTIONS
 *
 */

final _tryParseColorOptionInputs = {
  '': null,
  '0': null,
  '00': _defaultColor,
  '01': _opt01,
  '30': _opt30,
  '40': _opt40,
  '99': null,
  'asd': null,
  '@00001': null,
};

void _tryParseColorOptions(String input, Color? expected) {
  print(input);

  final it = input.runes.iterator;
  it.moveNext();
  final idx = it.rawIndex;

  Color? c = tryParseColorOption(it, _defaultColor);
  expect(c, equals(expected));

  if (c == null)
    expect(it.rawIndex, equals(idx));
  else
    expect(it.rawIndex, equals(input.length - 1));
}

/*
 * COLOR CODES (STD + EXT)
 *
 */

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
  '@*00000': Tuple2(Colors.black, RelayAttribute(bold: true)),
  '@_00000': Tuple2(Colors.black, RelayAttribute(underline: true)),
  '@|*_00000': Tuple2(
      Colors.black,
      RelayAttribute(
        keepAttributes: true,
        bold: true,
        underline: true,
      )),
};

void _tryParseColor(String input, var expected) {
  print(input);

  final it = input.runes.iterator;

  final c = tryParseColor(it, _defaultColor);
  if (expected is Color) {
    expect(c?.item1, equals(expected));
    expect(c?.item2, equals(null));
  } else
    expect(c, equals(expected));

  if (c == null)
    expect(it.rawIndex, equals(input.isEmpty ? -1 : 0));
  else
    expect(it.rawIndex, equals(input.length - 1));
}

/*
 * COLOR CODES (FULL)
 *
 */

final _colorCodeParserInputs = {
  // 0x19 + STD => color options!
  '\x1900': Tuple3(_defaultColor, null, null),
  '\x1901': Tuple3(_opt01, null, null),
  '\x1930': Tuple3(_opt30, null, null),
  '\x1940': Tuple3(_opt40, null, null),

  // 0x19 + EXT => not supported: ncurses pairs
  //'\x19@00214': Tuple3(_ext214, null, null),

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
  } else {
    expect(c.fgColor, equals(null));
    expect(c.fgTextStyle, equals(null));
    expect(c.bgColor, equals(null));

    expect(it.rawIndex, equals(0));
  }
}
