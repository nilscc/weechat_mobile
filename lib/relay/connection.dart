import 'dart:async';
import 'dart:io';

import 'package:weechat/relay/connection/status.dart';
import 'package:weechat/relay/protocol/message_body.dart';
import 'package:weechat/relay/protocol/parser.dart';

typedef Future<bool?> RelayCallback(RelayMessageBody body);

const String CONNECTION_CLOSED = 'Connection closed.';
const String CONNECTION_TIMEOUT = 'Connection timeout.';

class RelayConnection {
  SecureSocket? _socket;
  StreamSubscription? _streamSubscription;

  Map<String, RelayCallback> _callbacks = {};

  void addCallback(String id, RelayCallback callback) {
    _callbacks[id] = callback;
  }
  void removeCallback(String id) {
    _callbacks.remove(id);
  }

  RelayConnectionStatus connectionStatus;

  RelayConnection({required this.connectionStatus});

  bool get isConnected => connectionStatus.connected;

  Future<void> close({String? reason}) async {
    try {
      try {
        if (_socket != null) await _socket!.close();
      } catch (e) {
        // socket already closed
        if (!(e is StateError)) rethrow;
      }
      if (_streamSubscription != null) await _streamSubscription!.cancel();
      if (_pingTimer != null) _pingTimer!.cancel();
    } finally {
      _socket = null;
      _streamSubscription = null;
      _pingTimer = null;
      connectionStatus.reason = reason;
      connectionStatus.connected = false;
    }
  }

  Future<void> connect({
    required String hostName,
    required int portNumber,
    bool ignoreInvalidCertificate: true,
  }) async {
    try {
      _socket = await SecureSocket.connect(
        hostName,
        portNumber,
        onBadCertificate: (c) => ignoreInvalidCertificate,
        timeout: Duration(seconds: 1),
      );

      // start listening
      _streamSubscription = _socket!.listen((event) {
        final b = RelayParser(event).body();
        _handleMessageBody(b);
      });

      connectionStatus.connected = true;
    } catch (e) {
      if (e is SocketException)
        close();
      rethrow;
    }
  }

  Future<void> command(
    String id,
    String command, {
    RelayCallback? callback,
    String? responseId,
    Duration? callbackTimeout,
  }) async {
    if (_socket == null) return;

    // setup callback
    Completer? c;
    if (callback != null) {
      c = Completer();
      _callbacks[responseId ?? id] = (b) async {
        await callback(b);
        c!.complete();
      };

      // add timeout to future, otherwise it might get stuck when connection is lost
      c.future.timeout(callbackTimeout ?? Duration(seconds: 1)).catchError((e) {
        if (e is TimeoutException)
          close(reason: CONNECTION_TIMEOUT);
        else
          throw e;
      });
    }

    // run command and catch possible exception
    try {
      _socket!.write('($id) $command\n');
      await _socket!.flush();
      if (c != null) await c.future;
    } catch (e, s) {
      print(e);
      print(s);
      if (e is StateError)
        close(reason: CONNECTION_CLOSED);
      else
        rethrow;
    }
  }

  Future<void> _handleMessageBody(final RelayMessageBody body) async {
    if (_callbacks.containsKey(body.id)) {
      final b = await _callbacks[body.id]!(body);
      if (b != true)
        _callbacks.remove(body.id);
    } else {
      print('Unhandled message body: ${body.id}');
    }
  }

  Future<void> handshake() async {
    await command(
      'handshake',
      'handshake',
      callback: (body) async {
        // TODO
      },
    );
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
