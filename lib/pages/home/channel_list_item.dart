import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weechat/pages/channel.dart';
import 'package:weechat/relay/buffer.dart';
import 'package:weechat/relay/connection.dart';

class ChannelListItem extends StatelessWidget {
  final String bufferPointer, name, topic, plugin;
  final int nickCount;

  ChannelListItem({
    required this.bufferPointer,
    required this.name,
    required this.topic,
    required this.plugin,
    required this.nickCount,
  });

  @override
  Widget build(BuildContext context) {
    final con = Provider.of<RelayConnection>(context, listen: false);
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: GestureDetector(
        onTap: () async {
          // create relay buffer instance for channel
          final buffer = RelayBuffer(
            relayConnection: con,
            name: name,
            bufferPointer: bufferPointer,
          );
          buffer.sync();

          try {
            // open channel page
            await Navigator.of(context).push(
              ChannelPage.route(buffer: buffer),
            );
          } finally {
            // send desync when channel got closed
            buffer.desync();
          }
        },
        child: Card(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  child: Text(
                    this.name,
                    style: theme.textTheme.headline6,
                  ),
                ),
                if (this.topic.isNotEmpty)
                  Container(
                    padding: EdgeInsets.only(top: 5),
                    child: Text(
                      this.topic,
                      style: theme.textTheme.caption,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
