import 'package:weechat/relay/connection.dart';
import 'package:weechat/relay/protocol/hdata.dart';

class RelayHotlistEntry {
  final DateTime creationTime;
  final String pointer, buffer;
  final int priority;
  final List<int> count;

  RelayHotlistEntry({
    required this.creationTime,
    required this.pointer,
    required this.buffer,
    required this.priority,
    required this.count,
  });

  @override
  String toString() => 'RelyHotlistEntry(creationTime: $creationTime, '
      'pointer: $pointer, buffer: $buffer, priority: $priority, count: $count)';
}

Future<List<RelayHotlistEntry>> loadRelayHotlist(
  RelayConnection connection, {
  Future Function(RelayHotlistEntry changedEntry)? hotlistChanged,
}) async {
  List<RelayHotlistEntry> hotlist = [];

  var syncCmd = '';
  if (hotlistChanged != null) {
    connection.addCallback('_hotlist_changed', (b) async {
      for (final RelayHData h in b.objects()) {
        for (final o in h.objects) {
          await hotlistChanged.call(RelayHotlistEntry(
            creationTime: DateTime.fromMicrosecondsSinceEpoch(
                o.values[1].toInt() * 1000000 + o.values[2].toInt()),
            pointer: o.pPath[0],
            buffer: o.values[3],
            priority: o.values[0],
            count: (o.values[4] as List).map((e) => e as int).toList(),
          ));
        }
      }
    }, repeat: true);

    // immediately start syncing hotlist
    syncCmd = '\nsync * hotlist';
  }

  await connection.command(
    'hdata hotlist:gui_hotlist(*) '
    'priority,creation_time.tv_sec,creation_time.tv_usec,buffer,count'
    '$syncCmd',
    callback: (reply) async {
      for (final RelayHData h in reply.objects()) {
        for (final o in h.objects) {
          hotlist.add(RelayHotlistEntry(
            pointer: o.pPath[0],
            priority: o.values[0],
            creationTime: DateTime.fromMicrosecondsSinceEpoch(
                o.values[1].toInt() * 1000000 + o.values[2].toInt()),
            buffer: o.values[3],
            count: (o.values[4] as List).map((i) => i as int).toList(),
          ));
        }
      }
    },
  );

  return hotlist;
}
