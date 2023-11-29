import 'package:weechat/relay/connection.dart';
import 'package:weechat/relay/protocol/message_body.dart';

class NicklistData {}

class RelayBufferNicklist {
  final RelayConnection connection;
  final String bufferId;

  RelayBufferNicklist({
    required this.connection,
    required this.bufferId,
  });

  Map<String, List<NicklistData>> get groups => Map.unmodifiable(_groups);
  final Map<String, List<NicklistData>> _groups = {};

  Future<void> load() async {
    await connection.command(
      "nicklist $bufferId",
      callback: (RelayMessageBody body) {
        for (final o in body.objects()) {
          print(o); // TODO: sort objects into _groups
        }
      },
    );
  }
}
