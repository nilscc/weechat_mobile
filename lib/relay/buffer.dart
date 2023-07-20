import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:weechat/pages/log/event_logger.dart';
import 'package:weechat/relay/connection.dart';
import 'package:weechat/relay/protocol/hdata.dart';
import 'package:weechat/relay/protocol/line_data.dart';

class RelayBuffer extends ChangeNotifier {
  final RelayConnection relayConnection;
  final String bufferPointer, name;
  final List<LineData> lines = [];

  bool get active => _active;
  bool _active = false;

  String? _lastLinePointer;
  String? _firstLinePointer;

  EventLogger? get _eventLogger => relayConnection.connectionStatus.eventLogger;

  RelayBuffer({
    required this.relayConnection,
    required this.bufferPointer,
    required this.name,
  });

  Future<void> desync() async {
    _removeCallbacks();
    await relayConnection.command('desync $bufferPointer buffer');
    _active = false;
  }

  Future<void> sync({int lastLineCount = 50}) async {
    _addCallbacks();

    // hdata command to receive recent lines
    final hdataCmd = 'hdata'
        ' buffer:$bufferPointer/own_lines/last_line(-$lastLineCount)/data'
        ' $lineDataSelected';

    final syncCmd = 'sync $bufferPointer buffer';

    await relayConnection.command(
      '$hdataCmd\n$syncCmd',
      callback: (body) async {
        var success = false;
        for (final RelayHData hdata in body.objects()) {
          if (hdata.objects.isNotEmpty) {
            lines.addAll(handleLineData(hdata, 3));
            // set first line only while we haven't been successful yet
            if (!success) {
              _firstLinePointer = hdata.objects.first.pPath[2];
            }
            _lastLinePointer = hdata.objects.last.pPath[2];
            success = true;
          }
        }
        if (success) {
          _active = true;
          notifyListeners();
        }
      },
    );
  }

  void _addCallbacks() {
    relayConnection.addCallback(
      '_buffer_line_added',
      (body) async {
        // invalidate pointer to first line
        _firstLinePointer = null;

        for (final RelayHData obj in body.objects()) {
          if (obj.hPath == 'line') {
            // store information about last line
            _firstLinePointer = obj.objects.first.pPath[0];
          } else if (obj.hPath == 'line_data') {
            // add lines to buffer
            for (final l in handleLineData(obj, 0)) {
              lines.insert(0, l);
            }
          }
        }

        notifyListeners();
      },
      repeat: true,
    );
  }

  void _removeCallbacks() {
    relayConnection.removeCallback('_buffer_line_added');
  }

  Future<void> loadNext({int lineCount = 50}) async {
    // hdata command to receive recent lines
    final hdataCmd = 'hdata'
        ' line:$_lastLinePointer/prev_line(-$lineCount)/data'
        ' $lineDataSelected';

    await relayConnection.command(
      hdataCmd,
      callback: (body) async {
        var success = false;

        final o = body.objects();
        for (final RelayHData hdata in o) {
          if (hdata.objects.isNotEmpty) {
            success = true;
            lines.addAll(handleLineData(hdata, 2));
            _lastLinePointer = hdata.objects.last.pPath[1];
          }
        }

        if (success) notifyListeners();
      },
    );
  }

  Future<void> suspend() async {
    _active = false;
  }

  Future<void> resume() async {
    if (_firstLinePointer == null) {
      // perform full sync if first line pointer is not available
      lines.clear();
      _firstLinePointer = null;
      _lastLinePointer = null;
      return sync();
    }

    _loadNewLines();
  }

  String _indent(String lines, {int n = 4}) =>
      lines.split("\n").map((e) => "${' ' * n}$e").join("\n");

  Future<void> _loadNewLines() async {
    final hdataCmd = 'hdata'
        ' line:$_firstLinePointer/next_line(*)/data'
        ' $lineDataSelected';

    _eventLogger?.debug(
      "RelayBuffer._loadNewLines().hdataCmd =\n"
      "${_indent(hdataCmd)}",
    );

    final syncCmd = 'sync $bufferPointer buffer';

    _addCallbacks();

    await relayConnection.command(
      '$hdataCmd\n$syncCmd',
      callback: (body) async {
        List<String> fmt = [];
        String rawBytes = "";
        try {
          _eventLogger?.debug("RelayBuffer._loadNewLines().buffer =\n"
              "${_indent(body.buffer.asInt32x4List().join('\n'))}");

          final o = body.objects();
          fmt.add(o.toString());

          for (final RelayHData hdata in o) {
            if (hdata.objects.isNotEmpty) {
              for (final l in handleLineData(hdata, 0)) {
                lines.insert(0, l);
              }
              // next_line is sorted oldest to newest, so the first line is always the last one!
              _firstLinePointer = hdata.objects.last.pPath[1];
            }
          }
          // always notify listeners about active state change => no "success" variable needed
          _active = true;
          notifyListeners();
        } finally {
          _eventLogger?.debug("RelayBuffer._loadNewLines().body =\n"
              "${_indent(fmt.join('\n'), n: 4)}");
        }
      },
    );
  }
}
