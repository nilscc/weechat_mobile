import 'dart:async';
import 'dart:io';

import 'package:weechat/relay/message_body.dart';
import 'package:weechat/relay/parser.dart';

typedef Future<void> RelayCallback(RelayMessageBody body);

class RelayConnection {
  SecureSocket? _socket;
  StreamSubscription? _streamSubscription;

  Map<String, RelayCallback> _callbacks = {};

  bool isConnected() {
    return _socket != null;
  }

  Future<void> close() async {
    await _socket!.close();
    await _streamSubscription!.cancel();
    _socket = null;
    _streamSubscription = null;
  }

  Future<void> connect({
    required String hostName,
    required int portNumber,
    bool ignoreInvalidCertificate: true,
  }) async {
    _socket = await SecureSocket.connect(hostName, portNumber,
        onBadCertificate: (c) => ignoreInvalidCertificate);

    // start listening
    _streamSubscription = _socket!.listen((event) {
      final b = RelayParser(event).body();
      _handleMessageBody(b);
    });
  }

  Future<void> command(String id, String command,
      {RelayCallback? callback}) async {
    Completer? c;

    if (callback != null) {
      c = Completer();
      _callbacks[id] = (b) async {
        await callback(b);
        c!.complete();
      };
    }

    _socket!.write('($id) $command\n');
    if (c != null)
      await c.future;
  }

  Future<void> handshake() async {
    await command('handshake', 'handshake');
  }

  Future<void> init(String relayPassword) async {
    relayPassword = relayPassword.replaceAll(',', '\\,');
    await command('init', 'init password=$relayPassword');
  }

  Future<void> test() async => command('test', 'test');

  Future<void> _handleMessageBody(final RelayMessageBody body) async {
    print(body.id);
    print(body.objects());
    if (_callbacks.containsKey(body.id)) {
      await _callbacks[body.id]!(body);
      _callbacks.remove(body.id);
    }
  }
}
