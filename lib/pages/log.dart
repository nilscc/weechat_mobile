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
  int? truncate;

  static const truncateDropdownValues = [
    DropdownMenuEntry(value: 20, label: "20"),
    DropdownMenuEntry(value: 50, label: "50"),
    DropdownMenuEntry(value: null, label: "None"),
  ];

  String _truncate(String message) {
    var lines = message.split("\n");
    final l = lines.length;
    if (truncate != null && l > truncate!) {
      lines = [
        ...lines.take((truncate!/2).round()),
        "",
        "<< truncated ${l - truncate!} lines >>",
        "",
        ...lines.skip(l - (truncate!/2).round()),
      ];
    }
    return lines.join("\n");
  }

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
                DropdownMenu<int?>(
                  dropdownMenuEntries: truncateDropdownValues,
                  initialSelection: truncateDropdownValues.first.value,
                  label: const Text("Truncate"),
                  onSelected: (val) => setState(() {
                    truncate = val;
                  }),
                ),
                const Spacer(),
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
                      .map((e) => Text('${e.item1} [${e.item2}]\n${_truncate(e.item3)}\n'))
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
