import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:weechat/relay/colors.dart';
import 'package:weechat/relay/connection.dart';
import 'package:weechat/relay/hdata.dart';

class LineData {
  final String lineDataPointer;

  final String bufferPointer;
  final DateTime date, datePrinted;
  final bool displayed;
  final int notifyLevel;
  final bool highlight;
  final List<String> tags;
  final String prefix, message;

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

const _lineDataSelected =
    'buffer,date,date_printed,displayed,notify_level,highlight,tags_array,prefix,message';

List<LineData> _handleLineData(
    RelayHData hdata, int lineDataPointerPPathIndex) {
  // hdata has format:
  // buffer,date,date_printed,displayed,notify_level,highlight,tags_array,prefix,message
  // 0      1    2            3         4            5         6          7      8

  final List<LineData> l = [];
  for (int i = 0; i < hdata.count; ++i) {
    final o = hdata.objects[i];
    final bufferPointer = o.values[0];
    final date = DateTime.fromMillisecondsSinceEpoch(o.values[1] * 1000);
    final datePrinted = DateTime.fromMillisecondsSinceEpoch(o.values[2] * 1000);
    final displayed = (o.values[3] as String).codeUnits[0] == 1;
    final notifyLevel = (o.values[4] as String).codeUnits[0];
    final highlight = (o.values[5] as String).codeUnits[0] == 1;

    final List<String> tags = [];
    for (final t in o.values[6])
      tags.add(t as String);

    final prefix = stripColors(o.values[7]);
    final message = stripColors(o.values[8]);

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

class RelayBuffer extends ChangeNotifier {
  final String bufferPointer, name;
  final List<LineData> lines = [];

  RelayBuffer({
    required this.bufferPointer,
    required this.name,
  });

  Future<void> desync(RelayConnection relayConnection) async {
    _removeCallbacks(relayConnection);
    await relayConnection.command('desync', 'desync $bufferPointer buffer');
  }

  Future<void> sync(RelayConnection relayConnection,
      {int lastLineCount: 50}) async {
    _addCallbacks(relayConnection);

    // hdata command to receive recent lines
    final hdataCmd = 'hdata'
        ' buffer:$bufferPointer/own_lines/last_line(-$lastLineCount)/data'
        ' $_lineDataSelected';

    final syncCmd = 'sync $bufferPointer buffer';

    relayConnection.command(
      'buffer_lines_sync',
      '$hdataCmd\n$syncCmd',
      callback: (body) async {
        for (final hdata in body.objects())
          lines.addAll(_handleLineData(hdata, 3));
        notifyListeners();
      },
    );
  }

  void _addCallbacks(RelayConnection relayConnection) {
    relayConnection.addCallback('_buffer_line_added', (body) async {
      for (final hdata in body.objects())
        for (final l in _handleLineData(hdata, 0))
          lines.insert(0, l);
      notifyListeners();
      return true; // keep callback persistent
    });
  }

  void _removeCallbacks(RelayConnection relayConnection) {
    relayConnection.removeCallback('_buffer_line_added');
  }
}
