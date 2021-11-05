import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:weechat/relay/buffer.dart';

class ChannelLines extends StatefulWidget {
  @override
  _ChannelLinesState createState() => _ChannelLinesState();
}

class _ChannelLinesState extends State<ChannelLines> {
  @override
  Widget build(BuildContext context) {
    final buffer = Provider.of<RelayBuffer>(context, listen: true);
    return ListView(
      reverse: true,
      children: [
        ...buffer.lines.map((e) => _buildLineData(context, e)),
      ],
    );
  }

  Widget _buildLineData(BuildContext context, LineData line) {
    final df = DateFormat.Hm().format(line.date);
    return Text('[$df] <${line.prefix}> ${line.message}');
  }
}
