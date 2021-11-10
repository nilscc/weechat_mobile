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
      print('Exception on RelayConnection.connect(): $e');
      if (e is SocketException) await close();
      rethrow;
    }
  }

  int _id = 0;
  String _nextId() => '__cmd_${_id++}';

  Future<void> command(
    String command, {
    RelayCallback? callback,
    String? responseId,
    Duration? callbackTimeout,
    FutureOr Function()? onTimeout,
  }) async {
    if (_socket == null) return;

    // get next id if not set manually
    final id = responseId ?? _nextId();

    // setup callback
    Future? f;
    if (callback != null) {
      final c = Completer();
      _callbacks[id] = (b) async {
        final r = await callback(b);
        c.complete();
        return r;
      };

      // add timeout to future, otherwise it might get stuck when connection is lost
      f = c.future.timeout(callbackTimeout ?? Duration(seconds: 1),
          onTimeout: onTimeout);
    }

    // run command and catch possible exception
    try {
      _socket!.write('($id) $command\n');
      await _socket!.flush();
      if (f != null) await f;
    } catch (e) {
      print('Exception on RelayConnection.command(): $e');
      if (e is StateError)
        await close(reason: CONNECTION_CLOSED);
      else if (e is TimeoutException)
        await close(reason: CONNECTION_TIMEOUT);
      else
        rethrow;
    }
  }

  Future<void> _handleMessageBody(final RelayMessageBody body) async {
    if (_callbacks.containsKey(body.id)) {
      final cb = _callbacks.remove(body.id)!;
      final b = await cb(body);
      if (b == true && !_callbacks.containsKey(body.id))
        _callbacks[body.id] = cb;
    } else {
      print('Unhandled message body: ${body.id} ${body.objects()}');
    }
  }

  Future<void> handshake() async {
    await command(
      'handshake',
      callback: (body) async {
        // TODO
      },
    );
  }

  Future<void> init(String relayPassword) async {
    relayPassword = relayPassword.replaceAll(',', '\\,');
    await command('init password=$relayPassword');
  }

  Future<Duration?> ping({Duration? timeout}) async {
    final c = Completer();
    final epoch = DateTime.now().microsecondsSinceEpoch;

    // send ping to relay
    await command(
      'ping $epoch',
      responseId: '_pong',
      callback: (b) async {
        if (b.objects()[0] == epoch.toString()) {
          final t = DateTime.now().microsecondsSinceEpoch;
          c.complete(Duration(microseconds: t - epoch));
        } else
          c.complete(null);
      },
      callbackTimeout: timeout,
      onTimeout: () {
        c.complete(null);
      },
    );

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

  Future<void> test() async => command('test');
}
