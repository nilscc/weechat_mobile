import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChannelLine extends StatelessWidget {
  final String lineDataPointer;
  final String prefix, message;
  final DateTime date;

  ChannelLine({
    required this.lineDataPointer,
    required this.prefix,
    required this.message,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.Hm().format(date);
    return Text('[$df] <$prefix> $message');
  }
}
