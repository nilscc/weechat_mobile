import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:http/http.dart' as http;
import 'package:weechat/relay/api/authentication.dart';

typedef Headers = Map<String, String>;

abstract class ApiClient {
  final AuthenticationMethod authenticationMethod;
  final Uri baseUri;

  ApiClient({
    required this.baseUri,
    required this.authenticationMethod,
  });

  factory ApiClient.fromUri(
    Uri baseUri,
    AuthenticationMethod authenticationMethod,
  ) {
    switch (baseUri.scheme) {
      case "ws":
      case "wss":
        return WebsocketClient(
          authenticationMethod: authenticationMethod,
          baseUri: baseUri,
        );
      default:
        return HttpClient(
          authenticationMethod: authenticationMethod,
          baseUri: baseUri,
        );
    }
  }
}

class HttpClient extends ApiClient {
  final bool compression;
  final http.Client client;

  static final Finalizer<http.Client> _clientFinalizer = Finalizer((c) {
    print("Closing client: ${identityHashCode(c)}");
    c.close();
  });

  HttpClient({
    required super.authenticationMethod,
    required super.baseUri,
    this.compression = false,
  }) : client = http.Client() {
    print("Using client: ${identityHashCode(client)}");
    _clientFinalizer.attach(this, client, detach: this);
  }

  void close() {
    client.close();
    _clientFinalizer.detach(this);
  }

  final MapEntry<String, String> _gzipEncoding = const MapEntry(
      "accept-encoding", "gzip"); // TODO: check if these are actually supported

  Headers _allHeaders(Headers? headers) => Map.fromEntries([
        // Enable compression if necessary
        if (compression) _gzipEncoding,
        // make sure to always send a "null" origin header:
        MapEntry("origin", "null"),
        // required authentication
        authenticationMethod.authorizationHeader(),
      ])
        ..addAll(headers ?? {});

  // GET request with all headers
  Future<String> read(String path, {Headers? headers}) {
    return client.read(
      baseUri.replace(path: path),
      headers: _allHeaders(headers),
    );
  }

  // GET request with all headers
  Future<http.Response> get(String path, {Headers? headers}) {
    return client.get(
      baseUri.replace(path: path),
      headers: _allHeaders(headers),
    );
  }

  // POST request with all headers
  Future<http.Response> post(
    String path, {
    Object? body,
    Headers? headers,
    Encoding? encoding,
  }) {
    return client.post(
      baseUri.replace(path: path),
      body: body,
      encoding: encoding,
      headers: _allHeaders(headers),
    );
  }
}

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

class WebsocketClient extends ApiClient {
  WebSocket? _webSocket;
  WebSocket? get webSocket => _webSocket;

  static final Finalizer<WebSocket> _finalizer = Finalizer((webSocket) {
    webSocket.close();
  });

  WebsocketClient({
    required super.baseUri,
    required super.authenticationMethod,
  });

  StreamSubscription? _streamSubscription;

  /// Duration used for [WebSocket.pingInterval]. Can be overriden in [connect].
  final defaultPingInterval = const Duration(seconds: 10);

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
        authenticationMethod.authorizationHeader(),
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
  final Map<int, RequestCallback> _callbacks = {};
  final Map<int, Completer> _completers = {};

  void _onData(data) async {
    final result = jsonDecode(data);
    final id = int.tryParse(result["request_id"]);
    if (id != null && _callbacks.containsKey(id)) {
      try {
        final status = StatusCode(result["code"], result["message"]);
        if (await (_callbacks[id]!.call(status, result["body"]))) {
          _callbacks.remove(id);
        }
      } finally {
        _completers[id]?.complete();
        _completers.remove(id);
      }
    }
  }

  /// Send of new request. Include the request method in [path]. See also
  /// implementations of [get], [options], [put], [post].
  /// [body] should only be used for `POST` and `PUT` as per API definition.
  Future<void> request(
    String path, {
    RequestCallback? callback,
    dynamic body,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final request = {
      "request": path,
    };

    // add request body if given
    if (body != null) {
      request["body"] = body;
    }

    Completer? completer;
    if (callback != null) {
      // increment request counter
      _requestCounter += 1;
      // store callback and set request ID
      _callbacks[_requestCounter] = callback;
      request["request_id"] = _requestCounter.toString();
      // store completer
      completer = _completers[_requestCounter] = Completer();
    }

    // send request encoded as json
    _webSocket?.add(jsonEncode(request));
    // wait for completion
    if (completer != null) {
      await completer.future.timeout(timeout);
    }
  }

  Future<void> get(String path, {RequestCallback? callback}) =>
      request("GET $path", callback: callback);
  Future<void> options(String path, {RequestCallback? callback}) =>
      request("OPTIONS $path", callback: callback);
  Future<void> put(String path, {RequestCallback? callback, dynamic body}) =>
      request("PUT $path", callback: callback, body: body);
  Future<void> post(String path, {RequestCallback? callback, dynamic body}) =>
      request("POST $path", callback: callback, body: body);
}
