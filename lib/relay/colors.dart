// See https://weechat.org/files/doc/stable/weechat_dev.en.html#color_codes_in_strings
// And also for reference:
// https://github.com/ubergeek42/weechat-android/blob/379f0863e9eef70d83462a5d13e8de932eb785b5/relay/src/main/java/com/ubergeek42/weechat/Color.java
// https://github.com/weechat/weechat/blob/12be3b8c332c75a398f77478fd8d62304c632a1e/src/gui/gui-color.h

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:weechat/relay/colors/color_code_parser.dart';
import 'package:weechat/relay/colors/rich_text_parser.dart';

//const _attributes = ['F', 'B', '*', '!', '/', '_', '|'];
const _combiners = [',', '~'];

RichText parseColors(
  String raw,
  Color defaultColor, {
  TextStyle? textStyle,
  int? alpha,
}) {
  final it = raw.runes.iterator;

  final p = RichTextParser(defaultFgColor: defaultColor, defaultAlpha: alpha);

  while (it.moveNext()) {
    final rawIndex = it.rawIndex;

    // SET ATTRIBUTE
    if (it.current == 0x1A) {
      // move to next char
      it.moveNext();

      final a = tryParseAttribute(it);
      if (a != null) p.attributes.set(a);
    }

    // REMOVE ATTRIBUTE
    else if (it.current == 0x1B) {
      // move to next char
      it.moveNext();

      final a = tryParseAttribute(it);
      if (a != null) p.attributes.remove(a);
    }

    // RESET
    else if (it.current == 0x1C) {
      // reset parser
      p.finalizeCurrentSpan();
      p.reset();
    }

    // COLOR CODE
    else if (it.current == 0x19) {
      p.finalizeCurrentSpan();

      ColorCodeParser ccp = ColorCodeParser(defaultFgColor: defaultColor);
      if (ccp.parse(it)) {
        if (ccp.fgColor != null) p.fgColor = ccp.fgColor;
        if (ccp.bgColor != null) p.bgColor = ccp.bgColor;
        if (ccp.attributes != null) p.attributes.set(ccp.attributes!);
      }
    } else if (it.current > 0) p.addText(it.currentAsString);
  }

  p.finalizeCurrentSpan();
  return RichText(text: p.span);
}

String stripColors(String raw) {
  return parseColors(raw, Colors.black).text.toPlainText();
}
