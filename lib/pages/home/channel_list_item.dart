import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weechat/pages/channel.dart';
import 'package:weechat/pages/log/event_logger.dart';
import 'package:weechat/relay/buffer.dart';
import 'package:weechat/relay/connection.dart';
import 'package:weechat/relay/hotlist.dart';

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

  Future<void> _openBuffer(
    BuildContext context, {
    Future Function()? beforeBufferOpened,
    Future Function()? onBufferRouteClosed,
  }) async {
    final con = Provider.of<RelayConnection>(context, listen: false);
    final log = EventLogger.of(context);

    // create relay buffer instance for channel
    final b = buffer(con);

    log.info('Buffer sync: $name');
    await b.sync();

    try {
      // run callback before opening buffer
      await beforeBufferOpened?.call();

      // open channel page
      await Navigator.of(context).push(
        ChannelPage.route(
          buffer: b,
        ),
      );
    } finally {
      // send desync when channel got closed
      log.info('Buffer desync: $name');
      await b.desync();

      // run callback if done
      await onBufferRouteClosed?.call();
    }
  }

  @override
  Widget build(
    BuildContext context, {
    RelayHotlistEntry? hotlist,
    Future Function()? beforeBufferOpened,
    Future Function()? onBufferRouteClosed,
  }) {
    final theme = Theme.of(context);

    var titleColor = theme.disabledColor;
    var captionColor = theme.colorScheme.onSurface.withAlpha(100);

    switch (hotlist?.priority) {
      case 0: // GUI_HOTLIST_LOW
        titleColor = theme.colorScheme.onBackground;
        break;
      case 1: // GUI_HOTLIST_MESSAGE
        titleColor = theme.colorScheme.secondary;
        break;
      case 2: // GUI_HOTLIST_PRIVATE
        titleColor = theme.colorScheme.secondary;
        break;
      case 3: // GUI_HOTLIST_HIGHLIGHT
        titleColor = theme.colorScheme.primary;
        break;
    }

    var titleStyle = theme.textTheme.headline6?.copyWith(
      color: titleColor,
    );
    var captionStyle = theme.textTheme.caption?.copyWith(
      color: captionColor,
    );

    return Container(
      key: key,
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: GestureDetector(
        onTap: () => _openBuffer(
          context,
          beforeBufferOpened: beforeBufferOpened,
          onBufferRouteClosed: onBufferRouteClosed,
        ),
        child: Card(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  child: Text(
                    this.name,
                    style: titleStyle,
                  ),
                ),
                if (this.topic.isNotEmpty)
                  Container(
                    padding: EdgeInsets.only(top: 5),
                    child: Text(
                      this.topic,
                      style: captionStyle,
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
