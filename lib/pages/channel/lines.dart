import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weechat/pages/channel/line_item.dart';
import 'package:weechat/relay/buffer.dart';

class ChannelLines extends StatefulWidget {
  final ScrollController? scrollController;

  ChannelLines({this.scrollController});

  @override
  _ChannelLinesState createState() => _ChannelLinesState();
}

class _ChannelLinesState extends State<ChannelLines> {
  @override
  Widget build(BuildContext context) {
    final buffer = Provider.of<RelayBuffer>(context, listen: true);

    return ListView.builder(
      controller: widget.scrollController,
      shrinkWrap: true,
      itemBuilder: (BuildContext context, int index) =>
          _buildLineData(context, buffer.lines[index]),
      itemCount: buffer.lines.length,
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    );
  }

  Widget _buildLineData(BuildContext context, LineData line) =>
      LineItem(line: line).build(context);
}
