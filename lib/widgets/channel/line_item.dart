import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:weechat/relay/protocol/line_data.dart';
import 'package:weechat/widgets/channel/urlify.dart';
import 'package:weechat/relay/colors.dart';

class LineItem extends StatelessWidget {
  final LineData line;

  const LineItem({required this.line, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final df = DateFormat.Hm().format(line.date);
    final th = Theme.of(context);
    final tt = th.textTheme;

    final isSystem = line.prefix.isEmpty ||
        ['<--', '-->', '--', '===', '=!='].any((e) => line.prefix.endsWith(e));
    final alpha = isSystem ? 100 : 255;
    final defaultColor = tt.bodyMedium?.color ?? th.colorScheme.onSurface;

    final isAction = [' *'].any((e) => line.prefix.endsWith(e));
    var bodyStyle = tt.bodyMedium;
    if (isAction) bodyStyle = bodyStyle?.copyWith(fontStyle: FontStyle.italic);

    final prefixRT = parseColors(line.prefix, defaultColor, alpha: alpha);
    final messageRT =
        parseColors(line.message, defaultColor, alpha: alpha).text as TextSpan;

    final dateRT = Container(
      padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 3),
      margin: const EdgeInsets.only(right: 5),
      color: line.highlight ? Colors.redAccent : null,
      child: RichText(
        text: TextSpan(
          text: df,
          style: tt.bodyMedium?.copyWith(
            fontFeatures: [const FontFeature.tabularFigures()],
            color: line.highlight ? Colors.white : Colors.grey.withAlpha(100),
          ),
        ),
      ),
    );

    final bodyRT = RichText(
      text: TextSpan(
        style: bodyStyle,
        children: [
          if (!(isSystem || isAction)) TextSpan(text: '<', style: tt.bodyMedium),
          if (!isAction) prefixRT.text,
          if (!isAction && line.prefix.isNotEmpty)
            TextSpan(text: isSystem ? ' ' : '> ', style: tt.bodyMedium),
          urlify(messageRT, onNotification: (msg) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(msg),
            ));
          }, localizations: loc),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [dateRT, Expanded(child: bodyRT)],
      ),
    );
  }
}