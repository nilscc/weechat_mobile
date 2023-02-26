import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tuple/tuple.dart';
import 'package:weechat/pages/home/channel_list.dart';
import 'package:weechat/relay/connection.dart';
import 'package:weechat/relay/hotlist.dart';
import 'package:weechat/widgets/home/channel_list_item.dart';

typedef ChannelFuture
    = Future<Tuple2<List<ChannelListItem>, List<RelayHotlistEntry>>>;

typedef OpenBufferCallback = Future<void> Function(
  ScaffoldState scaffoldState,
  RelayConnection connection,
  ChannelListItem channelListItem,
);

class ChannelListDrawer extends StatefulWidget {
  final OpenBufferCallback openBuffer;
  final ChannelFuture? channelFuture;

  const ChannelListDrawer({
    super.key,
    required this.openBuffer,
    required this.channelFuture,
  });

  @override
  State<ChannelListDrawer> createState() => _State();
}

class _State extends State<ChannelListDrawer> {
  @override
  Widget build(BuildContext context) {
    final con = RelayConnection.of(context, listen: false);
    return Drawer(
      child: ChannelList(
        channelFuture: widget.channelFuture,
        openBufferCallback: widget.openBuffer,
        relayConnection: con,
      ),
    );
  }
}
