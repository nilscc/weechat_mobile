import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:weechat/relay/api/authentication.dart';

typedef Headers = Map<String, String>;

class WebSocketClientException implements Exception {}

class FailedToConnect extends WebSocketClientException {}

class AlreadyConnected extends WebSocketClientException {}

class NotConnected extends WebSocketClientException {}

class OnDataException extends WebSocketClientException {
  final String message;
  OnDataException(this.message);
}

class WebsocketClient {
  /// Base websocket adress (could be either `ws://` or `wss://` for TLS)
  final Uri baseUri;

  /// Keep authentication method private, so we cannot read passwords externally
  final AuthenticationMethod _authenticationMethod;

  WebSocket? _webSocket;
  WebSocket? get webSocket => _webSocket;

  static final Finalizer<WebSocket> _finalizer = Finalizer((webSocket) {
    webSocket.close();
  });

  WebsocketClient({
    required this.baseUri,
    required AuthenticationMethod authenticationMethod,
  }) : _authenticationMethod = authenticationMethod;

  StreamSubscription? _streamSubscription;

  /// Duration used for [WebSocket.pingInterval]. Can be overriden in [connect].
  final defaultPingInterval = const Duration(seconds: 10);

  bool isConnected() => switch ((_webSocket, _streamSubscription)) {
        (final ws?, final _?) => ws.readyState == WebSocket.open,
        _ => false,
      };

  Future<void> connect({
    compressionOptions = CompressionOptions.compressionDefault,
    String? origin,
    Duration? pingInterval,
  }) async {
    if (isConnected()) {
      throw AlreadyConnected();
    }

    _webSocket = await WebSocket.connect(
      baseUri.replace(path: "/api").toString(),
      compression: compressionOptions,
      headers: Map.fromEntries([
        MapEntry("origin", origin ?? "null"),
        _authenticationMethod.authorizationHeader(),
      ]),
    );

    if (_webSocket case final ws?) {
      ws.pingInterval = pingInterval ?? defaultPingInterval;
      if (_onData case final od?) {
        _streamSubscription = ws.listen(od);
      }
      _finalizer.attach(this, ws, detach: this);
    } else {
      throw FailedToConnect();
    }
  }

  void close() {
    // cancel and close all streams
    _streamSubscription?.cancel();
    _webSocket?.close();
    _finalizer.detach(this);

    // set members to zero
    _streamSubscription = null;
    _webSocket = null;
  }

  OnDataCallback? _onData;
  set onData(OnDataCallback? onData) {
    // cancel old stream subscription
    if (_streamSubscription case final ss?) {
      ss.cancel();
      _streamSubscription = null;
    }
    // if callback given and websocket is up and running, start listening
    if ((onData, _webSocket) case (final od?, final ws?)) {
      _streamSubscription = ws.listen(od);
    }
    // assign
    _onData = onData;
  }

  void add(data) {
    if (_webSocket case final ws?) {
      ws.add(data);
    } else {
      throw NotConnected();
    }
  }
}

typedef OnDataCallback = FutureOr<void> Function(dynamic);
