import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:weechat/relay/connection/status.dart';
import 'package:weechat/relay/message_body.dart';
import 'package:weechat/relay/parser.dart';

typedef Future<void> RelayCallback(RelayMessageBody body);

class RelayConnection {
  SecureSocket? _socket;
  StreamSubscription? _streamSubscription;

  Map<String, RelayCallback> _callbacks = {};

  RelayConnectionStatus connectionStatus;
  void _connectionStatusListener() {
    if (!connectionStatus.connected) close();
  }

  RelayConnection({required this.connectionStatus}) {
    connectionStatus.addListener(_connectionStatusListener);
  }

  bool get isConnected => connectionStatus.connected;

  Future<void> close() async {
    try {
      if (_socket != null) await _socket!.close();
      if (_streamSubscription != null) await _streamSubscription!.cancel();
      if (_pingTimer != null) _pingTimer!.cancel();
    } finally {
      _socket = null;
      _streamSubscription = null;
      _pingTimer = null;
      connectionStatus.connected = false;
    }
  }

  Future<bool> connect({
    required String hostName,
    required int portNumber,
    bool ignoreInvalidCertificate: true,
  }) async {
    try {
      _socket = await SecureSocket.connect(hostName, portNumber,
          onBadCertificate: (c) => ignoreInvalidCertificate);

      // start listening
      _streamSubscription = _socket!.listen((event) {
        final b = RelayParser(event).body();
        _handleMessageBody(b);
      });

      connectionStatus.connected = true;
      return true;
    } catch (e) {
      if (e is SocketException) {
        close();
        return false;
      } else {
        rethrow;
      }
    }
  }

  Future<void> command(
    String id,
    String command, {
    RelayCallback? callback,
    String? responseId,
  }) async {
    if (_socket == null) return;

    Completer? c;
    if (callback != null) {
      c = Completer();
      _callbacks[responseId ?? id] = (b) async {
        await callback(b);
        c!.complete();
      };
    }

    _socket!.write('($id) $command\n');
    if (c != null) await c.future;
  }

  Future<void> _handleMessageBody(final RelayMessageBody body) async {
    if (_callbacks.containsKey(body.id)) {
      await _callbacks[body.id]!(body);
      _callbacks.remove(body.id);
    }
  }

  Future<void> handshake() async {
    await command('handshake', 'handshake');
  }

  Future<void> init(String relayPassword) async {
    relayPassword = relayPassword.replaceAll(',', '\\,');
    await command('init', 'init password=$relayPassword');
  }

  Future<Duration?> ping({Duration? timeout}) async {
    final c = Completer();
    final epoch = DateTime.now().microsecondsSinceEpoch;

    // send ping to relay
    final pingFuture = command(
      'ping',
      'ping $epoch',
      responseId: '_pong',
      callback: (b) async {
        if (b.objects()[0] == epoch.toString()) {
          final t = DateTime.now().microsecondsSinceEpoch;
          c.complete(Duration(microseconds: t - epoch));
        } else
          c.complete(null);
      },
    );

    // add timeout to ping callback
    pingFuture.timeout(timeout ?? Duration(seconds: 1), onTimeout: () {
      c.complete(null);
    });

    return await c.future;
  }

  Timer? _pingTimer;

  void startPingTimer({Duration? interval, Duration? timeout}) {
    if (_pingTimer == null) {
      // start pinging periodically in background
      _pingTimer = Timer.periodic(interval ?? Duration(seconds: 60), (t) async {
        print('Ping?');
        final p = await ping(timeout: timeout);
        if (p == null) {
          print('No PONG response from relay.');
          close();
        } else {
          print('Pong! ${p.inMilliseconds}ms');
        }
      });
    }
  }

  Future<void> test() async => command('test', 'test');
}
