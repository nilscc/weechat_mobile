import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';
import 'package:weechat/relay/colors/color_codes.dart';
import 'package:weechat/relay/colors/extended_definition.dart';

Color? tryParseColorOption(RuneIterator it, Color defaultColor) {
  Color? result;
  bool success = false;

  // before consuming iterator, store index so we can restore iterator position
  // if parsing fails
  final cur = it.rawIndex;
  if (cur == -1) return null; // uninitialized iterator

  String s = it.currentAsString;
  if (it.moveNext()) {
    s += it.currentAsString;
    if (s == '00') {
      result = defaultColor;
      success = true;
    } else {
      int? i = int.tryParse(s);
      if (i != null && colorOptions.containsKey(i)) {
        result = colorOptions[i] ?? defaultColor;
        success = true;
      }
    }
  }

  if (!success) {
    it.reset(cur);
    it.moveNext();
    return null;
  } else
    return result;
}

Tuple2<Color, RelayAttribute?>? tryParseColor(RuneIterator it, Color defaultColor) {
  Color? result;
  RelayAttribute? attribute;

  if (!it.moveNext()) return null;
  final cur = it.rawIndex;

  // Parse EXT color, defined by '@' + 2 zeros + 3 color code digits
  // (total 5 digits)
  if (it.currentAsString == '@') {
    String s = '';

    // parse optional attribute
    attribute = tryParseAttribute(it);

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
    it.moveNext();
    return null;
  } else
    return Tuple2(result, attribute);
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
  RelayAttribute? result;

  while (iterator.moveNext()) {
    if (['*', '/', '_', '|', '!', '\x01', '\x02', '\x03', '\x04'].contains(iterator.currentAsString)) {
      if (result == null)
        result = RelayAttribute();

      if (['*', '\x01'].contains(iterator.currentAsString))
        result.bold = true;
      else if (['/', '\x03'].contains(iterator.currentAsString))
        result.italic = true;
      else if (['_', '\x04'].contains(iterator.currentAsString))
        result.underline = true;
      else if (iterator.currentAsString == '|')
        result.keepAttributes = true;
      else if (['!', '\x02'].contains(iterator.currentAsString))
        result.reverse = true;
    } else {
      iterator.movePrevious();
      break;
    }
  }

  return result;
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

      // foreground mode
      if (iterator.currentAsString == 'F') {
        // parse attributes if any
        final a = tryParseAttribute(iterator);

        // parse color
        final c = tryParseColor(iterator, defaultFgColor);
        if (c != null) {
          fgColor = c.item1;
          attributes = a; // TODO: handle color attribute c.item2
          success = true;
        }
      }

      // background mode
      else if (iterator.currentAsString == 'B') {
        final c = tryParseColor(iterator, defaultBgColor ?? defaultFgColor);
        if (c != null) {
          bgColor = c.item1;
          // TODO: handle color attribute
          success = true;
        }
      }

      // star mode
      else if (iterator.currentAsString == '*') {
        // parse attributes if any
        final a = tryParseAttribute(iterator);

        // parse colors
        final c1 = tryParseColor(iterator, defaultFgColor);
        if (c1 != null) {
          fgColor = c1.item1;
          attributes = a; // TODO: handle color attribute c1.item2
          success = true;

          final idx = iterator.rawIndex;
          Tuple2<Color, RelayAttribute?>? c2;

          // peek if next character is combination character
          if (iterator.moveNext()) {
            if ([',', '~'].contains(iterator.currentAsString))
              c2 = tryParseColor(iterator, defaultBgColor ?? defaultFgColor);
          }

          if (c2 != null)
            bgColor = c2.item1; // TODO: handle color attribute
          else {
            iterator.reset(idx);
            iterator.moveNext();
          }
        }
      }

      // color option mode
      else {
        Color? c = tryParseColorOption(iterator, defaultFgColor);
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
