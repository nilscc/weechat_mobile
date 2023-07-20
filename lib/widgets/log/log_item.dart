import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:weechat/pages/log/event_logger.dart';

class LogItem extends StatelessWidget {
  final DateTime dateTime;
  final LogType logType;
  final String message;
  final int? truncate;

  const LogItem({
    required this.dateTime,
    required this.logType,
    required this.message,
    this.truncate,
    super.key,
  });

  Widget _truncate(String message) {
    final lines = message.split("\n");
    final l = lines.length;
    if (truncate != null && l > truncate!) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lines.take((truncate! / 2).round()).join("\n")),
          Text.rich(
            TextSpan(text: "\n<< truncated ${l - truncate!} lines >>\n"),
            style: const TextStyle(color: Colors.grey),
          ),
          Text(lines.skip(l - (truncate! / 2).round()).join("\n")),
        ],
      );
    } else {
      return Text(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);

    return GestureDetector(
      onLongPress: () async {
        await Clipboard.setData(ClipboardData(text: message));
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Copied log message to clipboard."),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(TextSpan(text: "$dateTime [$logType]", style: const TextStyle(color: Colors.grey))),
            _truncate(message),
          ],
        ),
      ),
    );
  }
}
