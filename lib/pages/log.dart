import 'package:flutter/material.dart';
import 'package:weechat/pages/log/event_logger.dart';

class LogPage extends StatelessWidget {
  static MaterialPageRoute route() =>
      MaterialPageRoute(builder: (context) => LogPage());

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('Logs'),
        ),
        body: Container(
          padding: EdgeInsets.all(10),
          child: ListView(
            children: EventLogger.of(context, listen: true)
                .messages
                .map((e) => Text('[${e.item1}] ${e.item2}'))
                .toList(),
          ),
        ),
      );
}
