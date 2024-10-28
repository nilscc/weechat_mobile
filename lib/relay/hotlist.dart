import 'package:weechat/relay/connection.dart';

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

Future<void> desyncHotlist(RelayConnection connection) async {
  await connection.command('desync * hotlist');
}

Future<List<RelayHotlistEntry>> loadRelayHotlist(
  RelayConnection connection, {
  Future Function(RelayHotlistEntry changedEntry)? hotlistChanged,
}) async {
  List<RelayHotlistEntry> hotlist = [];

  var syncCmd = '';
  if (hotlistChanged != null) {
    // connection.addCallback('_hotlist_changed', (b) async {
    //   for (final RelayHData h in b.objects()) {
    //     for (final o in h.objects) {
    //       await hotlistChanged.call(RelayHotlistEntry(
    //         pointer: o.pPath[0],
    //         priority: o.value('priority'),
    //         creationTime: DateTime.fromMicrosecondsSinceEpoch(
    //             o.value('time').toInt() * 1000000 +
    //                 o.value('time_usec').toInt()),
    //         buffer: o.value('buffer'),
    //         count: (o.value('count') as List).map((e) => e as int).toList(),
    //       ));
    //     }
    //   }
    // }, repeat: true);

    // immediately start syncing hotlist
    syncCmd = '\nsync * hotlist';
  }

  await connection.command(
    'hdata hotlist:gui_hotlist(*) '
    'priority,time,time_usec,buffer,count'
    '$syncCmd',
    callback: (reply) async {
      // for (final RelayHData h in reply.objects()) {
      //   for (final o in h.objects) {
      //     hotlist.add(RelayHotlistEntry(
      //       pointer: o.pPath[0],
      //       priority: o.value('priority'),
      //       creationTime: DateTime.fromMicrosecondsSinceEpoch(
      //           o.value('time').toInt() * 1000000 +
      //               o.value('time_usec').toInt()),
      //       buffer: o.value('buffer'),
      //       count: (o.value('count') as List).map((i) => i as int).toList(),
      //     ));
      //   }
      // }
    },
  );

  return hotlist;
}
