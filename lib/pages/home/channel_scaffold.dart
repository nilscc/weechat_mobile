import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:weechat/pages/home/channel_drawer.dart';

class ChannelScaffold extends StatefulWidget {
  final VoidCallback? onOpen, onClose;
  final AppBar? appBar;
  final ChannelFuture? channelFuture;
  final OpenBufferCallback openBufferCallback;
  final Widget? body;
  final Widget? floatingActionButton;

  const ChannelScaffold({
    super.key,
    required this.openBufferCallback,
    this.onOpen,
    this.onClose,
    this.appBar,
    this.channelFuture,
    this.body,
    this.floatingActionButton,
  });

  @override
  State<ChannelScaffold> createState() => _State();
}

class _State extends State<ChannelScaffold> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: ChannelListDrawer(
        openBuffer: widget.openBufferCallback,
        channelFuture: widget.channelFuture,
      ),
      onDrawerChanged: (isOpen) {
        isOpen ? widget.onOpen?.call() : widget.onClose?.call();
      },
      appBar: widget.appBar,
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
    );
  }
}
