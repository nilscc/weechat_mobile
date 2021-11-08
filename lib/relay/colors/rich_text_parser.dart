import 'package:flutter/material.dart';

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
  FontWeight? fontWeight;
  FontStyle? fontStyle;
  TextDecoration? textDecoration;

  void finalizeCurrentSpan() {
    if (_text != null) {
      _l.add(TextSpan(
          text: _text,
          style: TextStyle(
            color: (fgColor ?? defaultFgColor)?.withAlpha(defaultAlpha ?? 255),
            backgroundColor: bgColor ?? defaultBgColor,
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