import 'dart:async';
import 'dart:convert';

import 'package:weechat/relay/api/event.dart';
import 'package:weechat/relay/api/websocket.dart';

import 'package:weechat/relay/api/objects/buffer.dart';
import 'package:weechat/relay/api/objects/hotlist.dart';
import 'package:weechat/relay/api/objects/line.dart';
import 'package:weechat/relay/api/objects/nick.dart';
import 'package:weechat/relay/api/objects/nick_group.dart';

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

typedef EventCallback = FutureOr<void> Function(Event);

mixin JsonRequests {
  WebsocketClient get webSocket;
  EventCallback? onEvent;

  int _requestCounter = 0;
  final _completer = <String, Completer>{};

  void listen() {
    webSocket.onData = _onDataCallback;
  }

  dynamic _fromJson(final String bodyType, final body) => switch (bodyType) {
        "line" => Line.fromJson(body),
        "lines" => _fromJsonList<Line>(body),
        "buffer" => Buffer.fromJson(body),
        "buffers" => _fromJsonList<Buffer>(body),
        "nick" => Nick.fromJson(body),
        "nick_group" => NickGroup.fromJson(body),
        "hotlist" => _fromJsonList<Hotlist>(body),
        _ =>
          throw OnDataException("Failed to parse body type $bodyType\n$body"),
      };

  dynamic _fromJsonList<T>(body) => (body as List)
      // perform `T.fromJson()`, see workaround below
      .map((m) => _callFromJson[T]!(m as Map<String, dynamic>) as T)
      .toList();

  static const _callFromJson = {
    Buffer: Buffer.fromJson,
    Line: Line.fromJson,
    Nick: Nick.fromJson,
    Hotlist: Hotlist.fromJson,
  };

  /// Handle incoming [data], either via request ID or through events.
  void _onDataCallback(dynamic data) {
    final json = jsonDecode(data);
    print("json=$json");

    // construct response
    final status = StatusCode(json["code"], json["message"]);
    var body;
    if ((json["body_type"], json["body"]) case (final bodyType?, final json?)) {
      body = _fromJson(bodyType, json);
    }

    // check if request_id is part of json response
    if (json["request_id"] case final id?) {
      if (_completer.remove(id) case final completer?) {
        completer.complete(Response(status, body));
      } else {
        // TODO: log only
        print("Missing completer:\n$json");
      }
    } else if (json["message"] case "Event") {
      if (onEvent case final cb?) {
        cb.call(Event(json["event_name"], json["buffer_id"], body));
      } else {
        print("Unhandled event message:\n$json");
      }
    } else {
      print("Unhandled response:\n$json");
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
    assert(webSocket.isConnected());

    // increment counter
    _requestCounter += 1;
    final request = <String, dynamic>{
      "request": path,
      "request_id": "request_$_requestCounter",
    };

    // add request body if given
    if (body != null) {
      request["body"] = body;
    }

    // store completer for request ID
    final completer = Completer<Response>();
    _completer["request_$_requestCounter"] = completer;

    // send request encoded as json
    webSocket.add(jsonEncode(request));

    // wait for completion
    return completer.future.timeout(timeout);
  }

  Future<Response> get(String path) => request("GET $path");
  Future<Response> options(String path) => request("OPTIONS $path");
  Future<Response> put(String path, {dynamic body}) =>
      request("PUT $path", body: body);
  Future<Response> post(String path, {dynamic body}) =>
      request("POST $path", body: body);
}
