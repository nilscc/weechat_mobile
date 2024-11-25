// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weechat/pages/log/event_logger.dart';
import 'package:weechat/relay/api/authentication.dart';
import 'package:weechat/relay/api/client.dart';
import 'package:weechat/relay/connection/status.dart';

const String CONNECTION_CLOSED_REMOTE = 'Connection closed by remote.';
const String CONNECTION_CLOSED_OS = 'Connection closed by OS.';
const String CONNECTION_TIMEOUT = 'Connection timeout.';
const String CERTIFICATE_VERIFY_FAILED = 'Failed to verify the server '
    'certificate.';

const _DEFAULT_TIMEOUT = Duration(seconds: 10);
const _DEFAULT_PING_INTERVAL = Duration(seconds: 60);

class RelayConnection {
  /// Get relay connection of current context
  static RelayConnection of(BuildContext context, {listen = false}) =>
      Provider.of<RelayConnection>(context, listen: listen);

  // SecureSocket? _socket;
  ApiClient? client;
  // StreamSubscription? _socketSubscription;
  // DateTime? _socketCreated;

  // final Map<String, Completer<RelayMessageBody?>> _callbacks = {};

  RelayConnectionStatus connectionStatus;

  // reuse the event logger in the connection status
  EventLogger? get _eventLogger => connectionStatus.eventLogger;

  RelayConnection({required this.connectionStatus});

  bool get isConnected => connectionStatus.connected;

  String? _relayVersion;
  String? get relayVersion => _relayVersion;

  Future<void> close({String? reason}) async {
    // try {
    //   // cancel ping timer
    //   _pingTimer?.cancel();

    //   // cancel running commands
    //   for (var c in _runningCommands) {
    //     c.cancel();
    //   }

    //   // close connection properly
    //   try {
    //     _socket?.write('(desync) desync\n(quit) quit\n');
    //     await _socket?.flush();
    //   } catch (e) {
    //     _eventLogger?.error('RelayConnection.close(): $e');
    //   }

    //   await _socketSubscription?.cancel();
    //   await _socket?.close();
    // } finally {
    //   _socket = null;
    //   _socketSubscription = null;
    //   _socketCreated = null;
    //   _pingTimer = null;
    //   // _callbacks.clear();
    //   _id = 0;
    //   connectionStatus.reason = reason;
    //   connectionStatus.connected = false;
    // }
  }

  Future connect({
    required String hostName,
    required int portNumber,
    required String password,
    bool ignoreInvalidCertificate = false,
  }) async {
    if (client != null) {
      _eventLogger?.error("Already connected!");
      return;
    }

    final uri = Uri(scheme: "wss", host: hostName, port: portNumber);
    final auth = PlainAuthentication(password);
    client = ApiClient(uri, auth);

    // TODO: set onEvent
    // client.onEvent = _onEvent;

    // perform the main connect
    await client?.connect();

    // check connection status
    connectionStatus.connected = client?.isConnected() ?? false;
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
}
