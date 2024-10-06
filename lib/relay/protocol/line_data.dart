import 'package:weechat/relay/protocol/hdata.dart';

class LineData {
  final String lineDataPointer;

  final String bufferPointer;
  final DateTime date, datePrinted;
  final bool displayed;
  final int notifyLevel;
  final bool highlight;
  final List<String> tags;
  final String? prefix;
  final String message;

  LineData({
    required this.lineDataPointer,
    required this.bufferPointer,
    required this.date,
    required this.datePrinted,
    required this.displayed,
    required this.notifyLevel,
    required this.highlight,
    required this.tags,
    required this.prefix,
    required this.message,
  });
}

const lineDataSelected =
    'buffer,date,date_usec,date_printed,date_usec_printed,displayed,notify_level,highlight,tags_array,prefix,message';

List<LineData> handleLineData(
  RelayHData hdata,
  int lineDataPointerPPathIndex,
) {
  final List<LineData> l = [];
  for (int i = 0; i < hdata.count; ++i) {
    final o = hdata.objects[i];

    // get members
    final bufferPointer = o.value("buffer");
    final date = DateTime.fromMillisecondsSinceEpoch(o.value("date") * 1000);
    final datePrinted =
        DateTime.fromMillisecondsSinceEpoch(o.value("date_printed") * 1000);
    final displayed = (o.value("displayed") as String).codeUnits[0] == 1;
    final notifyLevel = (o.value("notify_level") as String).codeUnits[0];
    final highlight = (o.value("highlight") as String).codeUnits[0] == 1;
    final tags =
        (o.value("tags_array") as List).map((e) => e as String).toList();
    final prefix = o.value("prefix");
    final message = o.value("message");

    l.add(LineData(
      lineDataPointer: o.pPath[lineDataPointerPPathIndex],
      bufferPointer: bufferPointer,
      date: date,
      datePrinted: datePrinted,
      displayed: displayed,
      notifyLevel: notifyLevel,
      highlight: highlight,
      tags: tags,
      prefix: prefix,
      message: message,
    ));
  }
  return l;
}
