import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weechat/pages/channel.dart';
import 'package:weechat/pages/log/event_logger.dart';
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
    Key? key,
  }) : super(key: key);

  RelayBuffer buffer(RelayConnection connection) => RelayBuffer(
    relayConnection: connection,
    name: name,
    bufferPointer: bufferPointer,
  );

  void _openBuffer(BuildContext context) async {
    final con = Provider.of<RelayConnection>(context, listen: false);
    final log = EventLogger.of(context);

    // create relay buffer instance for channel
    final b = buffer(con);

    log.info('Buffer sync: $name');
    b.sync();

    try {
      // open channel page
      await Navigator.of(context).push(
        ChannelPage.route(
          buffer: b,
        ),
      );
    } finally {
      // send desync when channel got closed
      log.info('Buffer desync: $name');
      b.desync();
    }
  }

  @override
  Widget build(
    BuildContext context, {
    ChannelListItem? prev,
    ChannelListItem? next,
  }) {
    final theme = Theme.of(context);

    return Container(
      key: key,
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: GestureDetector(
        onTap: () => _openBuffer(context),
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
