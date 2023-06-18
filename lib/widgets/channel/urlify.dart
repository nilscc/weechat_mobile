import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:validators/validators.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

bool _validUrl(String text) => isURL(
      text,
      protocols: ['https', 'http'],
      requireProtocol: true,
      requireTld: true,
    );

WidgetSpan urlWidget(
  String url,
  TextStyle style, {
  void Function(String text)? onNotification,
  AppLocalizations? localizations,
}) {
  final u = Uri.parse(url);

  // widget for the URL
  return WidgetSpan(
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        child: Text.rich(
          TextSpan(text: url),
          style: style.copyWith(color: Colors.blue),
        ),
        onTap: () {
          launchUrl(u, mode: LaunchMode.externalApplication);
        },
        onLongPress: () async {
          await Clipboard.setData(ClipboardData(text: u.toString()));
          onNotification?.call(
              localizations?.urlifyCopiedMessage(u.toString()) ?? u.toString());
        },
      ),
    ),
  );
}

TextSpan urlify(
  TextSpan input, {
  void Function(String text)? onNotification,
  AppLocalizations? localizations,
}) {

  // the list of child spans will be filled only if we find any urls
  List<InlineSpan> children = [];

  // temporary text variable which stores all text so far processed
  var txt = '';

  // iterate over all words in the input and look for URLs
  var words = input.text?.split(' ');
  for (final String word in (words ?? [])) {
    if (_validUrl(word)) {
      // url found -> combine text before URL with new URL widget
      if (txt.isNotEmpty) {
        children.add(TextSpan(text: '$txt '));
        txt = '';
      }
      children.add(urlWidget(
        word,
        input.style ?? const TextStyle(),
        onNotification: onNotification,
        localizations: localizations,
      ));
    } else {
      // no URL found, append text to temporary buffer
      txt += ' $word';
    }
  }

  // final result is either the unchanged input or a new text span with all text/url children
  if (children.isEmpty) {
    return input;
  } else {
    return TextSpan(
      children: children,
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
}
