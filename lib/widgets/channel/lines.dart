import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weechat/widgets/channel/line_item.dart';
import 'package:weechat/relay/buffer.dart';

class ChannelLines extends StatefulWidget {
  final ScrollController? scrollController;

  const ChannelLines({super.key, this.scrollController});

  @override
  State<ChannelLines> createState() => _ChannelLinesState();
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

  // install scroll listener to fetch new messages when offset is less than
  // view port dimension
  void _scrollControlListener() {
    final p = widget.scrollController!.position;
    final d = p.viewportDimension;
    final o = widget.scrollController!.offset;
    final r = p.maxScrollExtent;
    if ((o > (r - d)) && _nextLinesFuture == null) {
      _nextLinesFuture = Future(_nextLines);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_scrollControlListener);
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_scrollControlListener);
    super.dispose();
  }

  final _focusNode = FocusNode(debugLabel: 'channel lines');

  @override
  Widget build(BuildContext context) {
    // load buffer required by _nextLines()
    _buffer ??= Provider.of<RelayBuffer>(context, listen: false);

    // update build, so load buffer again and listen
    final buffer = Provider.of<RelayBuffer>(context, listen: true);

    return Focus(
      focusNode: _focusNode,
      child: GestureDetector(
        onVerticalDragDown: (_) => _focusNode.requestFocus(),
        child: ListView.builder(
          controller: widget.scrollController,
          shrinkWrap: true,
          itemBuilder: (BuildContext context, int index) =>
              _buildLineData(context, buffer.lines[index]),
          itemCount: buffer.lines.length,
          reverse: true,
        ),
      ),
    );
  }

  Widget _buildLineData(BuildContext context, LineData line) =>
      LineItem(line: line).build(context);
}
