import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';
import 'package:weechat/pages/home/channel_drawer.dart';
import 'package:weechat/relay/connection.dart';
import 'package:weechat/relay/hotlist.dart';
import 'package:weechat/widgets/home/channel_list_item.dart';

class ChannelList extends StatelessWidget {
  final ChannelFuture? channelFuture;
  final OpenBufferCallback openBufferCallback;
  final RelayConnection relayConnection;

  const ChannelList({
    super.key,
    this.channelFuture,
    required this.openBufferCallback,
    required this.relayConnection,
  });

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: channelFuture,
        builder: (context, snapshot) {
          final scaffoldState = Scaffold.of(context);
          if (snapshot.hasData) {
            final t = snapshot.data as Tuple2;
            final l = t.item1 as List<ChannelListItem>;
            final h = t.item2 as List<RelayHotlistEntry>;

            // convert into lookup map
            final m =
                h.asMap().map((key, value) => MapEntry(value.buffer, value));

            return ListView(
              children: l
                  .map((e) => e.build(
                        context,
                        hotlist: m[e.bufferPointer],
                        openBuffer: (context) => openBufferCallback(
                            scaffoldState, relayConnection, e),
                      ))
                  .toList(),
            );
          } else {
            return Container();
          }
        },
      );
}
