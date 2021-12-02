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
  Future? _nextLinesFuture;
  RelayBuffer? _buffer;

  Future<void> _nextLines() async {
    try {
      await _buffer?.loadNext();
    } finally {
      _nextLinesFuture = null;
    }
  }

  @override
  void initState() {
    // install scroll listener to fetch new messages when offset is less than
    // view port dimension
    widget.scrollController?.addListener(() {
      final p = widget.scrollController!.position;
      final d = p.viewportDimension;
      final o = widget.scrollController!.offset;
      final r = p.maxScrollExtent;
      if ((o > (r - d)) && _nextLinesFuture == null)
        _nextLinesFuture = Future(_nextLines);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // load buffer required by _nextLines()
    if (_buffer == null)
      _buffer = Provider.of<RelayBuffer>(context, listen: false);

    // update build, so load buffer again and listen
    final buffer = Provider.of<RelayBuffer>(context, listen: true);

    return SafeArea(
      child: ListView.builder(
        controller: widget.scrollController,
        shrinkWrap: true,
        itemBuilder: (BuildContext context, int index) =>
            _buildLineData(context, buffer.lines[index]),
        itemCount: buffer.lines.length,
        reverse: true,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      ),
    );
  }

  Widget _buildLineData(BuildContext context, LineData line) =>
      LineItem(line: line).build(context);
}
