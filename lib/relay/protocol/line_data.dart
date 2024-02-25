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
  // hdata has format:
  // buffer,date,date_usec,date_printed,date_usec_printed,displayed,notify_level,highlight,tags_array,prefix,message
  // 0      1    2         3            4                 5         6            7         8          9      10

  final List<LineData> l = [];
  for (int i = 0; i < hdata.count; ++i) {
    final o = hdata.objects[i];
    final bufferPointer = o.values[0];
    final date = DateTime.fromMillisecondsSinceEpoch(o.values[1] * 1000);
    final datePrinted = DateTime.fromMillisecondsSinceEpoch(o.values[2] * 1000);
    final displayed = (o.values[5] as String).codeUnits[0] == 1;
    final notifyLevel = (o.values[6] as String).codeUnits[0];
    final highlight = (o.values[7] as String).codeUnits[0] == 1;
    final tags = (o.values[8] as List).map((e) => e as String).toList();
    final prefix = o.values[9];
    final message = o.values[10];

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
