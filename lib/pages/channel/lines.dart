import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:weechat/relay/buffer.dart';

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
    return Text('[$df] <${line.prefix}> ${line.message}');
  }
}
