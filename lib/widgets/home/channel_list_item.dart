import 'package:flutter/material.dart';
import 'package:weechat/relay/buffer.dart';
import 'package:weechat/relay/connection.dart';
import 'package:weechat/relay/hotlist.dart';

class ChannelListItem extends StatelessWidget {
  final String bufferPointer, name, fullName, topic, plugin;
  final int nickCount;

  const ChannelListItem({
    required this.bufferPointer,
    required this.name,
    required this.fullName,
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

  @override
  Widget build(
    BuildContext context, {
    RelayHotlistEntry? hotlist,
    Future Function(BuildContext)? openBuffer,
  }) {
    final theme = Theme.of(context);

    var titleColor = theme.disabledColor;
    var captionColor = theme.colorScheme.onSurface.withAlpha(100);

    switch (hotlist?.priority) {
      case 0: // GUI_HOTLIST_LOW
        titleColor = theme.colorScheme.onSurface.withAlpha(180);
        break;
      case 1: // GUI_HOTLIST_MESSAGE
        titleColor = theme.colorScheme.onSurface;
        break;
      case 2: // GUI_HOTLIST_PRIVATE
        titleColor = theme.colorScheme.onSurface;
        break;
      case 3: // GUI_HOTLIST_HIGHLIGHT
        titleColor = theme.colorScheme.primary;
        break;
    }

    var titleStyle = theme.textTheme.titleLarge?.copyWith(
      color: titleColor,
    );
    var captionStyle = theme.textTheme.bodySmall?.copyWith(
      color: captionColor,
    );

    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: GestureDetector(
        onTap: () async {
          await openBuffer?.call(context);
        },
        child: Card(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: titleStyle,
                ),
                if (topic.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      topic,
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
