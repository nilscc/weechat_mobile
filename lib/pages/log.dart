import 'package:flutter/material.dart';
import 'package:weechat/pages/log/event_logger.dart';

class LogPage extends StatelessWidget {
  const LogPage({super.key});

  static MaterialPageRoute route() =>
      MaterialPageRoute(builder: (context) => const LogPage());

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Logs'),
        ),
        body: Container(
          padding: const EdgeInsets.all(10),
          child: ListView(
            children: EventLogger.of(context, listen: true)
                .messages
                .reversed
                .map((e) => Text('${e.item1} [${e.item2}]\n${e.item3}\n'))
                .toList(),
          ),
        ),
      );
}
