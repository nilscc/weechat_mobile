import 'package:weechat/relay/connection.dart';
import 'package:weechat/relay/protocol/hdata.dart';

class RelayHotlistEntry {
  final DateTime creationTime;
  final String pointer, prevHotlist, nextHotlist, buffer;
  final int priority;
  final List<int> count;

  RelayHotlistEntry({
    required this.creationTime,
    required this.pointer,
    required this.prevHotlist,
    required this.nextHotlist,
    required this.buffer,
    required this.priority,
    required this.count,
  });

  @override
  String toString() => 'RelyHotlistEntry(creationTime: $creationTime, '
      'pointer: $pointer, prevHotlist: $prevHotlist, nextHotlist: $nextHotlist, '
      'buffer: $buffer, priority: $priority, count: $count)';
}

Future<List<RelayHotlistEntry>> loadRelayHotlist(RelayConnection connection) async {
  List<RelayHotlistEntry> hotlist = [];

  await connection.command(
    'hdata hotlist:gui_hotlist(*)',
    callback: (reply) async {
      for (final RelayHData h in reply.objects()) {
        for (final o in h.objects) {
          hotlist.add(RelayHotlistEntry(
            creationTime:
                DateTime.fromMillisecondsSinceEpoch(o.values[5] * 1000 + (o.values[0] / 1000).round()),
            pointer: o.pPath[0],
            prevHotlist: o.values[1],
            nextHotlist: o.values[4],
            buffer: o.values[6],
            priority: o.values[2],
            count: (o.values[3] as List).map((i) => i as int).toList(),
          ));
        }
      }
    },
  );

  return hotlist;
}
