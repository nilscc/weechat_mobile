import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:validators/validators.dart';

bool _validUrl(String text) => isURL(
      text,
      protocols: ['https', 'http'],
      requireProtocol: true,
      requireTld: true,
    );

TextSpan urlify(TextSpan input) {
  var words = input.text?.split(' ');

  var text;
  List<InlineSpan>? children;

  var idx = words?.indexWhere(_validUrl) ?? -1;
  if (idx == -1) {
    text = input.text;
  } else {
    children = [];
    String addSpace = '';

    while ((words ?? []).length > 0 && idx != -1) {
      final u = Uri.parse(words![idx]);

      children = children! +
          [
            // the text up to the URL
            if (idx > 0)
              TextSpan(
                text: addSpace + words.sublist(0, idx).join(' ') + ' ',
                style: input.style,
              ),

            // widget for the URL
            WidgetSpan(
              child: GestureDetector(
                child: RichText(
                  text: TextSpan(
                    style: (input.style ?? TextStyle())
                        .copyWith(color: Colors.blue),
                    text: words[idx],
                  ),
                ),
                onTap: () {
                  launch(u.toString());
                },
              ),
            ),
          ];

      // build words list for the rest of the input, then find next URL
      words = words.sublist(idx + 1);
      idx = words.indexWhere(_validUrl);
      addSpace = ' ';
    }

    // add remaining words if no more URLs have been found
    if (words!.length > 0)
      children = children! + [TextSpan(text: addSpace + words.join(' '))];
  }

  // urlify all children of input
  if (input.children?.isNotEmpty == true)
    children = (children ?? []) +
        input.children!.map((e) => (e is TextSpan) ? urlify(e) : e).toList();

  return TextSpan(
    text: text,
    children: children ?? input.children,
    style: input.style,
    locale: input.locale,
    mouseCursor: input.mouseCursor,
    onEnter: input.onEnter,
    onExit: input.onExit,
    recognizer: input.recognizer,
    semanticsLabel: input.semanticsLabel,
    spellOut: input.spellOut,
  );
}
