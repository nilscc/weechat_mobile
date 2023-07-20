import 'package:flutter/material.dart';
import 'package:weechat/pages/log/event_logger.dart';
import 'package:weechat/extensions/enum_comparison.dart';
import 'package:weechat/widgets/log/log_item.dart';

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

  final _controller = ScrollController();
  Widget? _upArrow;

  @override
  void initState() {
    super.initState();

    // show/hide up arrow dynamically
    _controller.addListener(() {
      if (!_controller.hasClients) {
        return;
      } else if (_upArrow == null && _controller.offset != 0) {
        setState(() {
          _upArrow = IconButton(
            icon: const Icon(Icons.arrow_upward),
            onPressed: () {
              _controller.animateTo(
                0,
                duration: const Duration(milliseconds: 100),
                curve: Curves.ease,
              );
            },
          );
        });
      } else if (_upArrow != null && _controller.offset == 0) {
        setState(() {
          _upArrow = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          IconButton(
            onPressed: () => EventLogger.of(context).clear(),
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      floatingActionButton: _upArrow,
      body: Padding(
        padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
        child: Column(
          children: [
            Row(
              children: [
                DropdownMenu<int?>(
                  dropdownMenuEntries: truncateDropdownValues,
                  initialSelection: truncateDropdownValues.first.value,
                  label: const Text("Max Lines"),
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
                  controller: _controller,
                  shrinkWrap: true,
                  children: EventLogger.of(context, listen: true)
                      .messages
                      .reversed
                      .where((element) => element.item2 >= logType)
                      .map((e) => LogItem(
                            dateTime: e.item1,
                            logType: e.item2,
                            message: e.item3,
                            truncate: truncate,
                          ))
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
