import 'package:flutter/material.dart';
import 'package:weechat/relay/colors/color_code_parser.dart';

class RichTextParser {
  RichTextParser({
    this.defaultFgColor,
    this.defaultBgColor,
    this.defaultAlpha,
  });

  // list of finished text spans
  final List<TextSpan> _l = [];

  TextSpan get span => _l.length == 1 ? _l[0] : TextSpan(children: _l);

  // current text
  String? _text;

  // detected colors
  int? defaultAlpha;
  final Color? defaultFgColor, defaultBgColor;
  Color? fgColor, bgColor;

  // detected font styles and weights
  RelayAttribute attributes = RelayAttribute();

  void finalizeCurrentSpan() {
    if (_text != null) {
      _l.add(TextSpan(
          text: _text,
          style: TextStyle(
            color: (fgColor ?? defaultFgColor)?.withAlpha(defaultAlpha ?? 255),
            backgroundColor: bgColor ?? defaultBgColor,
            fontWeight: attributes.bold == true ? FontWeight.bold : null,
            fontStyle: attributes.italic == true ? FontStyle.italic : null,
            decoration:
                attributes.underline == true ? TextDecoration.underline : null,
          )));
    }
    _text = null;
  }

  void reset() {
    fgColor = null;
    bgColor = null;
    if (attributes.keepAttributes != true) attributes = RelayAttribute();
  }

  void addText(String text) {
    _text = (_text ?? '') + text;
  }
}
