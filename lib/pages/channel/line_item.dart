import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:weechat/pages/channel/urlify.dart';
import 'package:weechat/relay/buffer.dart';
import 'package:weechat/relay/colors.dart';

class LineItem extends StatelessWidget {
  final LineData line;

  LineItem({required this.line});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final df = DateFormat.Hm().format(line.date);
    final th = Theme.of(context);
    final tt = th.textTheme;

    final isSystem = line.prefix.isEmpty ||
        ['<--', '-->', '--', '===', '=!='].any((e) => line.prefix.endsWith(e));
    final alpha = isSystem ? 100 : 255;
    final defaultColor = tt.bodyText2?.color ?? th.colorScheme.onSurface;

    final isAction = [' *'].any((e) => line.prefix.endsWith(e));
    var bodyStyle = tt.bodyText2;
    if (isAction) bodyStyle = bodyStyle?.copyWith(fontStyle: FontStyle.italic);

    //print('<${line.prefix}> ${line.message} (${line.message.codeUnits.map((e) => e.toRadixString(16)).toList()})');

    final prefixRT = parseColors(line.prefix, defaultColor, alpha: alpha).text;
    final messageRT =
        parseColors(line.message, defaultColor, alpha: alpha).text as TextSpan;

    final dateRT = Container(
      padding: EdgeInsets.symmetric(vertical: 1, horizontal: 3),
      margin: EdgeInsets.only(right: 5),
      color: line.highlight ? Colors.redAccent : null,
      child: RichText(
        text: TextSpan(
          text: '$df',
          style: tt.bodyText2?.copyWith(
            fontFeatures: [FontFeature.tabularFigures()],
            color: line.highlight ? Colors.white : Colors.grey.withAlpha(100),
          ),
        ),
      ),
    );

    final bodyRT = RichText(
      text: TextSpan(
        style: bodyStyle,
        children: [
          if (!(isSystem || isAction)) TextSpan(text: '<', style: tt.bodyText2),
          if (!isAction) prefixRT,
          if (!isAction && line.prefix.isNotEmpty)
            TextSpan(text: isSystem ? ' ' : '> ', style: tt.bodyText2),
          urlify(messageRT, onNotification: (msg) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(msg),
            ));
          }, localizations: loc),
        ],
      ),
    );

    return Container(
      padding: EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [dateRT, Expanded(child: bodyRT)],
      ),
    );
  }
}