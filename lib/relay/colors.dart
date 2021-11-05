// See https://weechat.org/files/doc/stable/weechat_dev.en.html#color_codes_in_strings
// And also for reference:
// https://github.com/ubergeek42/weechat-android/blob/379f0863e9eef70d83462a5d13e8de932eb785b5/relay/src/main/java/com/ubergeek42/weechat/Color.java
// https://github.com/weechat/weechat/blob/12be3b8c332c75a398f77478fd8d62304c632a1e/src/gui/gui-color.h

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const _attributes = ['F', 'B', '*', '!', '/', '_', '|'];
const _combiners = [',', '~'];

final colorCodes = {
  1: Colors.black,
  2: Colors.grey.shade800,
  3: Colors.red.shade900,
  4: Colors.red.shade400,
  5: Colors.green.shade800,
  6: Colors.green.shade400,
  7: Colors.brown,
  8: Colors.yellow,
  9: Colors.blue.shade800,
  10: Colors.lightBlue,
  11: Colors.pink.shade800,
  12: Colors.pink.shade400,
  13: Colors.cyan.shade800,
  14: Colors.cyan.shade400,
  15: Colors.grey,
  16: Colors.white,
};

class _ColorParser {
  // list of finished text spans
  final List<TextSpan> _l = [];

  TextSpan get span => _l.length == 1 ? _l[0] : TextSpan(children: _l);

  // current text
  String? _text;

  // detected colors
  Color? fgColor, bgColor;

  // detected font styles and weights
  FontWeight? fontWeight;
  FontStyle? fontStyle;

  void finalizeCurrentSpan() {
    if (_text != null) {
      _l.add(TextSpan(
          text: _text,
          style: TextStyle(
            color: fgColor,
            backgroundColor: bgColor,
            fontWeight: fontWeight,
            fontStyle: fontStyle,
          )));
    }
    _text = null;
  }

  void reset() {
    fgColor = null;
    bgColor = null;
    fontWeight = null;
    fontStyle = null;
  }

  void addText(String text) {
    _text = (_text ?? '') + text;
  }
}

RichText parseColors(String raw, {TextStyle? textStyle, int? alpha, Color? defaultColor}) {
  final it = raw.runes.iterator;

  final p = _ColorParser();

  while (it.moveNext()) {
    if (it.current == 0x1A || it.current == 0x1B) {
      // skip char
      it.moveNext();

      // TODO: handle attribute
      continue;
    }

    if (it.current == 0x1C) {
      // skip char
      it.moveNext();

      // reset parser
      p.finalizeCurrentSpan();
      p.reset();
    }

    if (it.current == 0x19) {
      // skip char
      it.moveNext();

      p.finalizeCurrentSpan();

      // skip attributes
      while (true) {
        if (_attributes.contains(it.currentAsString))
          it.moveNext();
        else
          break;
      }

      bool fg = true;

      while (true) {
        if (it.currentAsString == '@') {
          it.moveNext(); // skip @
          // extended: move 5 characters
          String s = it.currentAsString;
          it.moveNext();
          s += it.currentAsString;
          it.moveNext();
          s += it.currentAsString;
          it.moveNext();
          s += it.currentAsString;
          it.moveNext();
          s += it.currentAsString;
          it.moveNext();

          // TODO: assign extended color
          print('Extended: $s');
        } else {
          // standard: move 2 characters
          String s = it.currentAsString;
          it.moveNext();
          s += it.currentAsString;
          it.moveNext();

          int? cc = int.tryParse(s);
          if (cc != null) {
            Color? c;
            if (colorCodes.containsKey(cc)) c = colorCodes[cc];
            if (alpha != null)
              c = (c ?? defaultColor)?.withAlpha(alpha);
            if (fg)
              p.fgColor = c;
            else
              p.bgColor = c;
          }
        }

        // peek next character to check for combiners
        if (_combiners.contains(it.currentAsString)) {
          it.moveNext();
          fg = false;
        } else
          break;
      }
    }

    if (it.current > 0) p.addText(it.currentAsString);
  }

  p.finalizeCurrentSpan();
  return RichText(text: p.span);
}

String stripColors(String raw) {
  return parseColors(raw).text.toPlainText();
}
