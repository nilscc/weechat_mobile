import 'dart:async';

import 'package:weechat/relay/api/objects/hotlist.dart';
import 'package:weechat/relay/api/websocket.dart';
import 'package:weechat/relay/connection.dart';

typedef HostListChangedCb = FutureOr Function(RelayHotlistEntry changedEntry);

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
  // await connection.command('desync * hotlist');
}

Future<void> syncHotlist(RelayConnection connection,
    {required HostListChangedCb onHotlistChanged}) async {
  // await connection...

  //   connection.addCallback('_hotlist_changed', (b) async {
  //     for (final RelayHData h in b.objects()) {
  //       for (final o in h.objects) {
  //         await hotlistChanged.call(RelayHotlistEntry(
  //           pointer: o.pPath[0],
  //           priority: o.value('priority'),
  //           creationTime: DateTime.fromMicrosecondsSinceEpoch(
  //               o.value('time').toInt() * 1000000 +
  //                   o.value('time_usec').toInt()),
  //           buffer: o.value('buffer'),
  //           count: (o.value('count') as List).map((e) => e as int).toList(),
  //         ));
  //       }
  //     }
  //   }, repeat: true);

  //   // immediately start syncing hotlist
  //   syncCmd = '\nsync * hotlist';
}

Future<List<Hotlist>?> loadRelayHotlist(RelayConnection connection) async {
  // List<RelayHotlistEntry> hotlist = [];

  return connection.client?.hotlist();
}
