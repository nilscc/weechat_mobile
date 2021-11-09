import 'package:flutter/material.dart';
import 'package:weechat/relay/colors/color_codes.dart';
import 'package:weechat/relay/colors/extended_definition.dart';

Color? tryParseColor(RuneIterator it, Color defaultColor) {
  Color? result;

  // before consuming iterator, store index so we can restore iterator position
  // if parsing fails
  final cur = it.rawIndex;
  if (cur == -1) return null; // uninitialized iterator

  // Parse EXT color, defined by '@' + 2 zeros + 3 color code digits
  // (total 5 digits)
  if (it.currentAsString == '@') {
    String s = '';

    // lookup next 5 characters
    for (int i = 0; i < 5 && it.moveNext(); ++i) s += it.currentAsString;

    // check valid extended prefix (double 0)
    if (s.length == 5 && s[0] == '0' && s[1] == '0') {
      // lookup extended color code
      int? i = int.tryParse(s.substring(2));
      if (i != null) result = getExtendedColor(i);
    }
  } else {
    String s = it.currentAsString;
    if (it.moveNext()) {
      s += it.currentAsString;
      if (s == '00')
        result = defaultColor;
      else {
        int? i = int.tryParse(s);
        if (i != null && colorCodes.containsKey(i)) result = colorCodes[i];
      }
    }
  }

  if (result == null) {
    it.reset(cur);
    return null;
  } else
    return result;
}

class RelayAttribute {
  bool? bold;
  bool? italic;
  bool? reverse;
  bool? underline;
  bool? keepAttributes;

  RelayAttribute(
      {this.bold,
      this.italic,
      this.reverse,
      this.underline,
      this.keepAttributes});

  @override
  bool operator ==(Object other) =>
      (other is RelayAttribute) &&
      bold == other.bold &&
      italic == other.italic &&
      reverse == other.reverse &&
      underline == other.underline &&
      keepAttributes == other.keepAttributes;

  @override
  int get hashCode =>
      bold.hashCode +
      italic.hashCode +
      reverse.hashCode +
      underline.hashCode +
      keepAttributes.hashCode;

  void set(RelayAttribute other) {
    bold = other.bold ?? bold;
    italic = other.italic ?? italic;
    reverse = other.reverse ?? reverse;
    underline = other.underline ?? underline;
    keepAttributes = other.keepAttributes ?? underline;
  }

  void remove(RelayAttribute other) {
    if (other.bold == true) bold = null;
    if (other.italic == true) italic = null;
    if (other.reverse == true) reverse = null;
    if (other.underline == true) underline = null;
    if (other.keepAttributes == true) keepAttributes = null;
  }

  TextStyle get textStyle => TextStyle(
        decoration: underline == null ? null : TextDecoration.underline,
        fontWeight: bold == null ? null : FontWeight.bold,
        fontStyle: italic == null ? null : FontStyle.italic,
      );
}

RelayAttribute? tryParseAttribute(RuneIterator iterator) {
  if (iterator.rawIndex == -1) return null; // uninitialized iterator

  if (iterator.currentAsString == '*')
    return RelayAttribute(bold: true);
  else if (iterator.currentAsString == '/')
    return RelayAttribute(italic: true);
  else if (iterator.currentAsString == '_')
    return RelayAttribute(underline: true);
  else if (iterator.currentAsString == '|')
    return RelayAttribute(keepAttributes: true);
  else if (iterator.currentAsString == '!')
    return RelayAttribute(reverse: true);
}

class ColorCodeParser {
  final Color defaultFgColor;
  final Color? defaultBgColor;

  Color? fgColor, bgColor;
  RelayAttribute? attributes;

  TextStyle? get fgTextStyle => attributes?.textStyle;

  // Constructor
  ColorCodeParser({
    required this.defaultFgColor,
    this.defaultBgColor,
  });

  bool parse(RuneIterator iterator) {
    bool success = false;

    // before consuming iterator, store index so we can restore iterator position
    // if parsing fails
    final cur = iterator.rawIndex;
    if (cur == -1) {
      print('Uninitialized iterator.');
      return false; // uninitialized iterator
    }

    if (iterator.currentAsString == '\x19') {
      iterator.moveNext();

      // set foreground mode
      if (iterator.currentAsString == 'F') {
        iterator.moveNext();

        // parse attributes if any
        final a = tryParseAttribute(iterator);
        if (a != null)
          iterator.moveNext();

        // parse color
        Color? c = tryParseColor(iterator, defaultFgColor);
        if (c != null) {
          fgColor = c;
          attributes = a;
          success = true;
        }
      }

      // set background mode
      else if (iterator.currentAsString == 'B') {
        iterator.moveNext();
        Color? c = tryParseColor(iterator, defaultBgColor ?? defaultFgColor);
        if (c != null) {
          bgColor = c;
          success = true;
        }
      }

      // set star mode
      else if (iterator.currentAsString == '*') {
        iterator.moveNext();

        // parse attributes if any
        final a = tryParseAttribute(iterator);

        Color? c1 = tryParseColor(iterator, defaultFgColor);
        if (c1 != null) {
          fgColor = c1;
          attributes = a;
          success = true;

          final idx = iterator.rawIndex;
          Color? c2;

          // peek if next character is combination character
          if (iterator.moveNext()) {
            if ([',', '~'].contains(iterator.currentAsString)) {
              iterator.moveNext();
              c2 = tryParseColor(iterator, defaultBgColor ?? defaultFgColor);
            }
          }

          if (c2 != null)
            bgColor = c2;
          else {
            iterator.reset(idx);
            iterator.moveNext();
          }
        }
      }

      // parse regular color
      else {
        Color? c = tryParseColor(iterator, defaultFgColor);
        if (c != null) {
          fgColor = c;
          success = true;
        }
      }
    }

    if (success)
      return true;
    else {
      iterator.reset(cur);
      iterator.moveNext();
      return false;
    }
  }
}
