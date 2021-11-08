import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:weechat/relay/buffer.dart';
import 'package:weechat/relay/colors.dart';

class ChannelLines extends StatefulWidget {
  @override
  _ChannelLinesState createState() => _ChannelLinesState();
}

class _ChannelLinesState extends State<ChannelLines> {
  void _requestFocus() => FocusScope.of(context).requestFocus(FocusNode());

  @override
  Widget build(BuildContext context) {
    final buffer = Provider.of<RelayBuffer>(context, listen: true);
    return GestureDetector(
      onTap: _requestFocus,
      child: ListView(
        reverse: true,
        children: buffer.lines.map((e) => _buildLineData(context, e)).toList(),
      ),
    );
  }

  Widget _buildLineData(BuildContext context, LineData line) {
    final df = DateFormat.Hm().format(line.date);
    final tt = Theme.of(context).textTheme;

    final isSystem = ['<--', '-->', '--', '==='].any((e) => line.prefix.endsWith(e));
    final alpha = isSystem ? 100 : 255;
    final defaultColor = tt.bodyText2?.color ?? Colors.black;

    final prefixRT =
        parseColors(line.prefix, defaultColor, alpha: alpha).text;

    final messageRT =
        parseColors(line.message, defaultColor, alpha: alpha)
            .text;

    return Container(
      padding: EdgeInsets.only(top: 5),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$df ',
              style: tt.bodyText2?.copyWith(
                fontFeatures: [FontFeature.tabularFigures()],
                color: Colors.grey.withAlpha(100),
              ),
            ),
            if (!isSystem) TextSpan(text: '<', style: tt.bodyText2?.copyWith(

            )),
            prefixRT,
            TextSpan(text: isSystem ? ' ' : '> ', style: tt.bodyText2),
            messageRT,
          ],
        ),
      ),
    );
  }
}
