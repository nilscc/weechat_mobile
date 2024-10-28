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


