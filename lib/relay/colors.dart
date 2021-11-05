// See https://weechat.org/files/doc/stable/weechat_dev.en.html#color_codes_in_strings
// And also for reference:
// https://github.com/ubergeek42/weechat-android/blob/379f0863e9eef70d83462a5d13e8de932eb785b5/relay/src/main/java/com/ubergeek42/weechat/Color.java
// https://github.com/weechat/weechat/blob/12be3b8c332c75a398f77478fd8d62304c632a1e/src/gui/gui-color.h

import 'package:flutter/cupertino.dart';

const _attributes = ['F', 'B', '*', '!', '/', '_', '|'];
const _combiners = [',', '~'];

RichText parseColors(String raw) {
  final List<int> i = [];

  final it = raw.runes.iterator;
  while (it.moveNext()) {
    if (it.current == 0x1A || it.current == 0x1B) {
      it.moveNext();
      continue;
    }

    if (it.current == 0x1C) continue;

    if (it.current == 0x19) {
      it.moveNext();

      // skip attributes
      while (true) {
        if
        (_attributes.contains(it.currentAsString))
          it.moveNext();
        else
          break;
      }

      while (true) {
        if (it.currentAsString == '@') {
          it.moveNext(); // skip @
          // extended: move 5 characters
          it.moveNext();
          it.moveNext();
          it.moveNext();
          it.moveNext();
          it.moveNext();
        } else {
          // standard: move 2 characters
          it.moveNext();
          it.moveNext();
        }

        // peek next character to check for combiners
        if (_combiners.contains(it.currentAsString))
          it.moveNext();
        else
          break;
      }
    }

    i.add(it.current);
  }

  return RichText(text: TextSpan(text: String.fromCharCodes(i)));
}

String stripColors(String raw) {
  return parseColors(raw).text.toPlainText();
}
