import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tuple/tuple.dart';
import 'package:weechat/relay/connection.dart';
import 'package:weechat/relay/hotlist.dart';
import 'package:weechat/widgets/home/channel_list_item.dart';

class ChannelListDrawer extends StatefulWidget {
  final Future Function(
    ScaffoldState scaffoldState,
    RelayConnection connection,
    ChannelListItem channelListItem,
  ) openBuffer;

  Future<Tuple2<List<ChannelListItem>, List<RelayHotlistEntry>>>?
    channelFuture;

  ChannelListDrawer({
    super.key,
    required this.openBuffer,
    this.channelFuture,
  });

  @override
  State<ChannelListDrawer> createState() => _State();
}

class _State extends State<ChannelListDrawer> {
  @override
  Widget build(BuildContext context) {
    final con = RelayConnection.of(context, listen: false);
    return Drawer(
      child: FutureBuilder(
        future: widget.channelFuture,
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
                        openBuffer: (context) =>
                            widget.openBuffer(scaffoldState, con, e),
                      ))
                  .toList(),
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }
}
