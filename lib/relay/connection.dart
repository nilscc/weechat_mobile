import 'dart:async';
import 'dart:io';

import 'package:weechat/pages/log/event_logger.dart';
import 'package:weechat/relay/connection/status.dart';
import 'package:weechat/relay/protocol/message_body.dart';
import 'package:weechat/relay/protocol/parser.dart';

typedef Future<bool?> RelayCallback(RelayMessageBody body);

const String CONNECTION_CLOSED = 'Connection closed.';
const String CONNECTION_TIMEOUT = 'Connection timeout.';

class RelayConnection {
  SecureSocket? _socket;

  Map<String, RelayCallback> _callbacks = {};

  RelayConnectionStatus connectionStatus;

  // reuse the event logger in the connection status
  EventLogger? get _eventLogger => connectionStatus.eventLogger;

  RelayConnection({required this.connectionStatus});

  bool get isConnected => connectionStatus.connected;

  void dispose() {
    _socket?.close();
  }

  Future<void> close({String? reason}) async {
    try {
      _pingTimer?.cancel();

      // close connection properly
      try {
        _socket?.write('(quit) quit\n');
        await _socket?.flush();
      } catch (e) {
        _eventLogger?.error('RelayConnection.close(): $e');
      }

      _socket?.close();
    } finally {
      _socket = null;
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
      _socket!.listen((event) {
        final b = RelayParser(event).body();
        _handleMessageBody(b);
      });

      connectionStatus.connected = true;
    } catch (e) {
      _eventLogger?.error('RelayConnection.connect(): $e');
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
      f = c.future.timeout(callbackTimeout ?? Duration(seconds: 5),
          onTimeout: onTimeout);
    }

    // run command and catch possible exception
    try {
      _socket!.write('($id) $command\n');
      await _socket!.flush();
      if (f != null) await f;
    } catch (e) {
      _eventLogger?.error('RelayConnection.command($command): $e');
      if (e is StateError)
        await close(reason: CONNECTION_CLOSED);
      else if (e is TimeoutException)
        await close(reason: CONNECTION_TIMEOUT);
      else
        rethrow;
    }
  }

  void addCallback(String id, RelayCallback callback) {
    _callbacks[id] = callback;
  }

  void removeCallback(String id) {
    _callbacks.remove(id);
  }

  Future<void> _handleMessageBody(final RelayMessageBody body) async {
    if (_callbacks.containsKey(body.id)) {
      final cb = _callbacks.remove(body.id)!;
      final b = await cb(body);
      if (b == true && !_callbacks.containsKey(body.id))
        _callbacks[body.id] = cb;
    } else {
      _eventLogger?.warning('Unhandled message body: ${body.id} ${body.objects()}');
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
        _eventLogger?.info('Ping?');
        final p = await ping(timeout: timeout);
        if (p == null) {
          _eventLogger?.info('No PONG response from relay.');
          close();
        } else {
          _eventLogger?.info('Pong! ${p.inMilliseconds}ms');
        }
      });
    }
  }

  Future<void> test() async => command('test');
}
