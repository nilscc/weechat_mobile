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
  LogType logType = LogType.INFO;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                DropdownMenu(
                  label: const Text('Log Level'),
                  dropdownMenuEntries: LogType.values.reversed
                      .map((e) => DropdownMenuEntry(value: e, label: e.label))
                      .toList(),
                  onSelected: (val) {
                    if (val != null) {
                      setState(() {
                        logType = val;
                      });
                    }
                  },
                  initialSelection: logType,
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ListView(
                  shrinkWrap: true,
                  children: EventLogger.of(context, listen: true)
                      .messages
                      .reversed
                      .where((element) => element.item2 >= logType)
                      .map((e) => Text('${e.item1} [${e.item2}]\n${e.item3}\n'))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
