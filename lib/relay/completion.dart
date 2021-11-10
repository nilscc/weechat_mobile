import 'dart:async';
import 'dart:convert';

import 'package:tuple/tuple.dart';
import 'package:weechat/relay/connection.dart';
import 'package:weechat/relay/protocol/hdata.dart';

class RelayCompletion {
  final String context, baseWord;
  final int posStart, posEnd;
  final bool addSpace;
  final List<String> list;

  final String text;

  RelayCompletion({
    required this.context,
    required this.baseWord,
    required this.posStart,
    required this.posEnd,
    required this.addSpace,
    required this.list,
    required this.text,
  });

  @override
  String toString() =>
      'RelayCompletion(context: $context, baseWord: $baseWord, '
      'posStart: $posStart, posEnd: $posEnd, addSpace: $addSpace, list: $list, '
      'text: $text, _index: $_index, _position: $_position)';

  static int byteOffset(String text, int position) {
    final bytes = utf8.encode(text.substring(0, position));
    return bytes.length;
  }

  static int textPosition(String text, int byteOffset) {
    final bytes = utf8.encode(text).sublist(0, byteOffset);
    return utf8.decode(bytes).length;
  }

  static Future<RelayCompletion?> load(RelayConnection connection,
      String bufferPointer, String text, int position) async {
    final c = Completer();

    // run completion request
    await connection.command(
      'completion $bufferPointer $position $text',
      callback: (b) async {
        final h = b.objects()[0] as RelayHData;

        // check if response is empty (no completion available)
        if (h.objects.isEmpty) {
          c.complete(null);
          return;
        }

        final o = h.objects[0];

        // manually convert List<dynamic> to List<String>
        final list = (o.values[5] as List).map((e) => e as String).toList();

        c.complete(RelayCompletion(
          context: o.values[0],
          baseWord: o.values[1],
          // posStart is given as byte offset, see
          // https://github.com/weechat/weechat/issues/1590
          posStart: textPosition(text, o.values[2]),
          posEnd: o.values[3],
          addSpace: o.values[4] == 1,
          list: list,
          text: text,
        ));
      },
    );

    return await c.future;
  }

  int _index = 0;
  int? _position;

  int? get position => _position;

  Tuple2<String, int> next() {
    // start and end of new text are fix
    final start = text.substring(0, posStart);
    final end = text.substring(posStart + baseWord.length);

    // figure out middle part and new position
    String mid = '';
    if (_index < list.length) {
      mid = list[_index];

      // add space if necessary to middle section
      if (addSpace) mid += ' ';

      ++_index;
    } else {
      // go back to base
      mid = baseWord;
      _index = 0;
    }

    return Tuple2(start + mid + end, posStart + mid.length);
  }
}
