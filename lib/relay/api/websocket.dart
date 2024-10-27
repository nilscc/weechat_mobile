import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:weechat/relay/api/authentication.dart';

typedef Headers = Map<String, String>;

enum WebSocketClientExceptionReason implements Exception {
  alreadyConnected,
}

class WebSocketClientException implements Exception {
  final WebSocketClientExceptionReason reason;

  WebSocketClientException.alreadyConnected()
      : reason = WebSocketClientExceptionReason.alreadyConnected;
}

class StatusCode {
  final int code;
  final String message;
  StatusCode(this.code, this.message);
}

/// Function used in [WebsocketClient] callbacks. Receives the status code
/// [status] and  decoded request [body] as argument.
/// Return `true` if the callback should be removed (one time callback) or kept,
/// e.g. for regular `sync` callbacks.
typedef RequestCallback = Future<bool> Function(
  StatusCode status,
  dynamic body,
);

class Response {
  final StatusCode status;
  final dynamic body;

  Response(this.status, [this.body]);
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
    if (_webSocket != null || _streamSubscription != null) {
      throw WebSocketClientException.alreadyConnected();
    }

    _webSocket = await WebSocket.connect(
      baseUri.replace(path: "/api").toString(),
      compression: compressionOptions,
      headers: Map.fromEntries([
        MapEntry("origin", origin ?? "null"),
        _authenticationMethod.authorizationHeader(),
      ]),
    );

    _webSocket!.pingInterval = pingInterval ?? defaultPingInterval;
    _streamSubscription = _webSocket!.listen(_onData);

    _finalizer.attach(this, _webSocket!, detach: this);
  }

  void close() {
    if (_webSocket == null) {
      return;
    }
    _webSocket!.close();
    _webSocket = null;
    _finalizer.detach(this);
  }

  int _requestCounter = 0;
  final _completer = <int, Completer<Response>>{};

  void _onData(data) async {
    final result = jsonDecode(data);
    // check if theres a request_id
    if (int.tryParse(result["request_id"]) case final id?) {
      // get the correct completer for the ID
      if (_completer.remove(id) case final completer?) {
        // construct response
        final status = StatusCode(result["code"], result["message"]);
        final body = result["body"];
        completer.complete(Response(status, body));
      }
    } else {
      throw "Unhandled data:\n$data";
    }
  }

  /// Send of new request. Include the request method in [path]. See also
  /// implementations of [get], [options], [put], [post].
  /// [body] should only be used for `POST` and `PUT` as per API definition.
  Future<Response> request(
    String path, {
    dynamic body,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    assert(isConnected());

    final request = {
      "request": path,
      "request_id": (++_requestCounter).toString(), // increment counter
    };

    // add request body if given
    if (body != null) {
      request["body"] = body;
    }

    // store completer for request ID
    final completer = Completer<Response>();
    _completer[_requestCounter] = completer;

    // send request encoded as json
    _webSocket?.add(jsonEncode(request));

    // wait for completion
    return completer.future.timeout(timeout);
  }

  Future<Response> get(String path, {RequestCallback? callback}) =>
      request("GET $path");
  Future<Response> options(String path, {RequestCallback? callback}) =>
      request("OPTIONS $path");
  Future<Response> put(String path,
          {RequestCallback? callback, dynamic body}) =>
      request("PUT $path", body: body);
  Future<Response> post(String path,
          {RequestCallback? callback, dynamic body}) =>
      request("POST $path", body: body);
}
