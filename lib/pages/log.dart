import 'package:flutter/material.dart';
import 'package:weechat/pages/log/event_logger.dart';
import 'package:weechat/extensions/enum_comparison.dart';

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  static MaterialPageRoute route() =>
      MaterialPageRoute(builder: (context) => const LogPage());

  @override
  State<StatefulWidget> createState() => _State();
}

class _State extends State<LogPage> {
  LogType logType = LogType.DEBUG;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
      ),
      body: Container(
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: EventLogger.of(context, listen: true)
              .messages
              .reversed
              .where((element) => element.item2 >= logType)
              .map((e) => Text('${e.item1} [${e.item2}]\n${e.item3}\n'))
              .toList(),
        ),
      ),
    );
  }
}
