import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:validators/validators.dart';
import 'package:weechat/l10n/app_localizations.dart';

bool validUrl(String text) => isURL(
      text,
      protocols: ['https', 'http'],
      requireProtocol: true,
      requireTld: true,
      allowUnderscore: true,
    );

WidgetSpan urlWidget(
  String url, {
  TextStyle? style,
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
          TextSpan(
            text: url,
            style: style?.copyWith(color: Colors.blue),
          ),
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
  TextStyle? style,
  void Function(String text)? onNotification,
  AppLocalizations? localizations,
}) {
  // the list of child spans will be filled only if we find any urls
  List<InlineSpan> children = [];

  if (input.text != null) {
    children.addAll(urlifyText(
      input.text ?? "",
      style: style?.merge(input.style) ?? input.style,
      onNotification: onNotification,
      localizations: localizations,
    ));
  }

  for (final inlineSpan in input.children ?? []) {
    children.addAll(urlifyInlineSpan(
      inlineSpan,
      style: style,
      onNotification: onNotification,
      localizations: localizations,
    ));
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

List<InlineSpan> urlifyInlineSpan(
  InlineSpan inlineSpan, {
  TextStyle? style,
  void Function(String text)? onNotification,
  AppLocalizations? localizations,
}) {
  final res = <InlineSpan>[];
  if (inlineSpan is TextSpan) {
    if (inlineSpan.text != null) {
      res.addAll(urlifyText(
        inlineSpan.text!,
        style: style?.merge(inlineSpan.style) ?? inlineSpan.style,
        onNotification: onNotification,
        localizations: localizations,
      ));
    } else {
      res.add(inlineSpan);
    }
    for (final child in inlineSpan.children ?? []) {
      res.addAll(urlifyInlineSpan(
        child,
        style: style,
        onNotification: onNotification,
        localizations: localizations,
      ));
    }
  }
  return res;
}

List<InlineSpan> urlifyText(
  String text, {
  TextStyle? style,
  void Function(String text)? onNotification,
  AppLocalizations? localizations,
}) {
  // the list of child spans will be filled only if we find any urls
  List<InlineSpan> spans = [];

  // temporary text variable which stores all text so far processed
  final nonUrlWords = <String>[];

  // iterate over all words in the input and look for URLs
  final words = text.split(' ');
  for (final String word in words) {
    if (validUrl(word)) {
      // url found -> combine text before URL with new URL widget
      if (nonUrlWords.isNotEmpty) {
        spans.add(TextSpan(
          text: '${nonUrlWords.join(' ')} ',
          style: style,
        ));
        nonUrlWords.clear();
      }
      spans.add(urlWidget(
        word,
        style: style,
        onNotification: onNotification,
        localizations: localizations,
      ));
    } else {
      // no URL found, append text to temporary buffer
      nonUrlWords.add(word);
    }
  }

// add final text span
  if (nonUrlWords.isNotEmpty) {
    final space = spans.isEmpty ? '' : ' ';
    spans.add(TextSpan(
      text: '$space${nonUrlWords.join(' ')}',
      style: style,
    ));
  }

  return spans;
}
