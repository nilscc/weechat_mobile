import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:weechat/pages/settings/config.dart';
import 'package:weechat/relay/protocol/line_data.dart';
import 'package:weechat/widgets/channel/urlify.dart';
import 'package:weechat/relay/colors.dart';

class LineItem extends StatelessWidget {
  final LineData line;

  const LineItem({required this.line, super.key});

  @override
  Widget build(BuildContext context) {
    final cfg = Config.of(context, listen: true);
    final loc = AppLocalizations.of(context);
    final df = DateFormat.Hm().format(line.date);
    final th = Theme.of(context);
    final tt = th.textTheme;
    final st = tt.bodyMedium?.copyWith(fontSize: cfg.fontSize?.toDouble());

    final isSystem = line.prefix == null ||
        line.prefix!.isEmpty ||
        ['<--', '-->', '--', '===', '=!='].any((e) => line.prefix!.endsWith(e));
    final alpha = isSystem ? 100 : 255;
    final defaultColor = st?.color ?? th.colorScheme.onSurface;

    final isAction = [' *'].any((e) => line.prefix?.endsWith(e) ?? false);
    var bodyStyle = st;
    if (isAction) bodyStyle = bodyStyle?.copyWith(fontStyle: FontStyle.italic);

    Text? prefixRT;
    if (line.prefix != null) {
      prefixRT = parseColors(line.prefix!, defaultColor, alpha: alpha);
    }

    final messageRT = parseColors(line.message, defaultColor, alpha: alpha)
        .textSpan! as TextSpan;

    final dateRT = Container(
      padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 3),
      margin: const EdgeInsets.only(right: 5),
      color: line.highlight ? Colors.redAccent : null,
      child: Text.rich(
        style: st?.copyWith(
          fontFeatures: [const FontFeature.tabularFigures()],
          color: line.highlight ? Colors.white : Colors.grey.withAlpha(100),
        ),
        TextSpan(text: df),
      ),
    );

    final bodyRT = Text.rich(
      style: bodyStyle,
      TextSpan(children: [
        if (!(isSystem || isAction)) const TextSpan(text: '<'),
        if (!isAction && prefixRT != null) prefixRT.textSpan!,
        if (!isAction && (line.prefix?.isNotEmpty ?? false))
          isSystem ? const TextSpan(text: ' ') : const TextSpan(text: '> '),
        urlify(
          messageRT,
          style: bodyStyle,
          onNotification: (msg) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
              ),
            );
          },
          localizations: loc,
        ),
      ]),
    );

    return Container(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectionContainer.disabled(child: dateRT),
          Expanded(child: bodyRT),
          const Visibility(
            visible: false,
            maintainState: true,
            child: Text('\r'), // why \r and not \n ???
          ),
        ],
      ),
    );
  }
}
