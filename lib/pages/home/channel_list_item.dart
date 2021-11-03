import 'package:flutter/material.dart';
import 'package:weechat/pages/channel.dart';
import 'package:weechat/relay/connection/status.dart';

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
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: GestureDetector(
        onTap: () {
          final cf = Navigator.of(context).push(
            ChannelPage.route(
              bufferPointer: bufferPointer,
              name: name,
            ),
          );
        },
        child: Card(
          child: ListTile(
            title: Text(name),
            subtitle: Text('Topic: "$topic"\n$nickCount users'), // TODO: l10n
          ),
        ),
      ),
    );
  }
}
