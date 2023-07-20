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
    return Text('$dateTime[$logType]\n${_truncate(message)}\n');
  }
}
