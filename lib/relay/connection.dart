// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weechat/pages/log/event_logger.dart';
import 'package:weechat/relay/connection/status.dart';

const String CONNECTION_CLOSED_REMOTE = 'Connection closed by remote.';
const String CONNECTION_CLOSED_OS = 'Connection closed by OS.';
const String CONNECTION_TIMEOUT = 'Connection timeout.';
const String CERTIFICATE_VERIFY_FAILED = 'Failed to verify the server '
    'certificate.';

const _DEFAULT_TIMEOUT = Duration(seconds: 10);
const _DEFAULT_PING_INTERVAL = Duration(seconds: 60);

class RelayConnection {
  static RelayConnection of(BuildContext context, {listen = false}) =>
      Provider.of<RelayConnection>(context, listen: listen);

  SecureSocket? _socket;
  StreamSubscription? _socketSubscription;
  DateTime? _socketCreated;

  // final Map<String, Completer<RelayMessageBody?>> _callbacks = {};

  RelayConnectionStatus connectionStatus;

  // reuse the event logger in the connection status
  EventLogger? get _eventLogger => connectionStatus.eventLogger;

  RelayConnection({required this.connectionStatus});

  bool get isConnected => connectionStatus.connected;

  String? _relayVersion;
  String? get relayVersion => _relayVersion;

  Future<void> close({String? reason}) async {
    try {
      // cancel ping timer
      _pingTimer?.cancel();

      // cancel running commands
      for (var c in _runningCommands) {
        c.cancel();
      }

      // close connection properly
      try {
        _socket?.write('(desync) desync\n(quit) quit\n');
        await _socket?.flush();
      } catch (e) {
        _eventLogger?.error('RelayConnection.close(): $e');
      }

      await _socketSubscription?.cancel();
      await _socket?.close();
    } finally {
      _socket = null;
      _socketSubscription = null;
      _socketCreated = null;
      _pingTimer = null;
      // _callbacks.clear();
      _id = 0;
      connectionStatus.reason = reason;
      connectionStatus.connected = false;
    }
  }

  Future<void> connect({
    required String hostName,
    required int portNumber,
    bool ignoreInvalidCertificate = true,
  }) async {
    try {
      _socket = await SecureSocket.connect(
        hostName,
        portNumber,
        onBadCertificate: (c) => ignoreInvalidCertificate,
        timeout: const Duration(seconds: 1),
      );
      _socketCreated = DateTime.now();

      // start listening
      _socketSubscription = _socket!.listen((event) async {
        // final b = RelayParser(event).body();
        // await _handleMessageBody(b);
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

  // Store running commands in a list so we can cancel them if the connection is
  // closed
  final List<CancelableOperation> _runningCommands = [];

  Future<T?> command<T>(
    String command, {
    FutureOr<T?> Function(dynamic /* TODO */)? callback,
    String? responseId,
    Duration? timeout,
    FutureOr<T?> Function()? onTimeout,
  }) async {
    if (_socket == null) return null;

    // get next id if not set manually
    final id = responseId ?? _nextId();

    // setup callback
    // Completer<RelayMessageBody?>? c;
    // if (callback != null) {
    //   c = Completer<RelayMessageBody?>();
    //   _callbacks[id] = c;
    // }

    // run command and catch possible exception
    try {
      // _socket!.write('($id) $command\n');
      // await _socket!.flush();

      // // execute callback
      // if (c != null) {
      //   final co = CancelableOperation.fromFuture(c.future.timeout(
      //     timeout ?? _DEFAULT_TIMEOUT,
      //     onTimeout: onTimeout == null ? null : () => null,
      //   ));
      //   _runningCommands.add(co);

      //   RelayMessageBody? m;
      //   try {
      //     m = await co.valueOrCancellation();
      //   } finally {
      //     _runningCommands.remove(co);
      //   }

      //   if (m != null) {
      //     return await callback?.call(m);
      //   } else {
      //     return await onTimeout?.call();
      //   }
      // }
    } catch (e) {
      _eventLogger?.error('RelayConnection.command($command): $e');
      if (e is StateError) {
        await close(reason: CONNECTION_CLOSED_REMOTE);
      } else if (e is TimeoutException) {
        await close(reason: CONNECTION_TIMEOUT);
      } else {
        rethrow;
      }
    }
    return null;
  }

  // void addCallback(String id, FutureOr Function(RelayMessageBody) callback,
  //     {bool repeat = false}) {
  //   final c = Completer<RelayMessageBody?>();
  //   _callbacks[id] = c;
  //   c.future.then((value) async {
  //     if (value != null) {
  //       await callback(value);
  //       if (repeat) addCallback(id, callback, repeat: repeat);
  //     }
  //   });
  // }

  // void removeCallback(String id) {
  //   _callbacks.remove(id);
  // }

  // Future<void> _handleMessageBody(final RelayMessageBody body) async {
  //   if (_callbacks.containsKey(body.id)) {
  //     final c = _callbacks.remove(body.id)!;
  //     c.complete(body);
  //   } else {
  //     _eventLogger
  //         ?.warning('Unhandled message body: ${body.id} ${body.objects()}');
  //   }
  // }

  Future<void> init(String relayPassword) async {
    // perform handshake
    await command('handshake compression=zlib', callback: (_) {});

    // authenticate with relay
    relayPassword = relayPassword.replaceAll(',', '\\,');
    await command('init password=$relayPassword');

    // also get version info. this also verifies authentication was successful
    await command(
      'info version',
      callback: (reply) async {
        _relayVersion = reply.objects()[0].item2;
      },
    );
  }

  Future<Duration?> ping({Duration? timeout}) async {
    final t1 = DateTime.now().microsecondsSinceEpoch;
    _eventLogger?.debug('Ping? $t1');
    return await command(
      'ping $t1',
      responseId: '_pong',
      timeout: timeout,
      onTimeout: () {
        _eventLogger?.warning('No PONG response from relay.');
        return null;
      },
      callback: (b) {
        final tr = b.objects()[0];
        if (tr == t1.toString()) {
          final t2 = DateTime.now().microsecondsSinceEpoch;
          final p = Duration(microseconds: t2 - t1);
          _eventLogger?.debug('Pong! ${p.inMilliseconds}ms');
          return p;
        } else {
          _eventLogger?.warning('Invalid PONG response: $tr');
        }
        return null;
      },
    );
  }

  Timer? _pingTimer;

  void startPingTimer({Duration? interval, Duration? timeout}) {
    final created = _socketCreated;
    // start pinging periodically in background
    _pingTimer ??= Timer.periodic(
      interval ?? _DEFAULT_PING_INTERVAL,
      (t) async {
        final p = await ping(timeout: timeout);
        if (p == null && created == _socketCreated) await close();
      },
    );
  }

  Future<void> test() async => command('test');
}
