import 'package:weechat/relay/connection.dart';
import 'package:weechat/relay/protocol/message_body.dart';

class NicklistData {
  final String name;
  final String color;
  final String prefix;
  final String prefix_color;

  NicklistData({
    required this.name,
    required this.color,
    required this.prefix,
    required this.prefix_color,
  });
}

class RelayBufferNicklist {
  final RelayConnection connection;
  final String bufferId;

  RelayBufferNicklist({
    required this.connection,
    required this.bufferId,
  });

  Map<String, List<NicklistData>> get groups => Map.unmodifiable(_groups);
  final Map<String, List<NicklistData>> _groups = {};

  Future<List<NicklistData>?> load() async {
    return await connection.command(
      "nicklist $bufferId",
      callback: (RelayMessageBody body) {
        final lst = <NicklistData>[];
        for (final hdata in body.objects()) {
          for (final obj in hdata.objects) {
            print(obj);
            // sort objects into _groups
            if (obj.values[0] == "\x01") {
              continue;
            } else {
              lst.add(NicklistData(
                name: obj.values[3],
                color: obj.values[4],
                prefix: obj.values[5],
                prefix_color: obj.values[6],
              ));
            }
          }
        }
        return lst;
      },
    );
  }
}
