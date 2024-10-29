import 'dart:async';
import 'dart:convert';

import 'package:weechat/relay/api/authentication.dart';
import 'package:weechat/relay/api/event.dart';
import 'package:weechat/relay/api/json_requests.dart';
import 'package:weechat/relay/api/objects/buffer.dart';
import 'package:weechat/relay/api/objects/hotlist.dart';
import 'package:weechat/relay/api/objects/line.dart';
import 'package:weechat/relay/api/objects/nick.dart';
import 'package:weechat/relay/api/websocket.dart';

typedef IdOrName = dynamic;

class ApiException implements Exception {}

class UnexpectedStatus extends ApiException {
  final StatusCode code;
  UnexpectedStatus(this.code);
}

class UnexpectedResponseBody extends ApiException {
  final dynamic body;
  UnexpectedResponseBody(this.body);
}

class UnexpectedRequest extends ApiException {
  final String message;
  UnexpectedRequest(this.message);
}

class ApiClient with JsonRequests {
  final WebsocketClient _websocket;

  @override
  WebsocketClient get webSocket => _websocket;

  ApiClient(Uri baseUri, AuthenticationMethod authenticationMethod)
      : _websocket = WebsocketClient(
          baseUri: baseUri,
          authenticationMethod: authenticationMethod,
        );

  Future<void> connect() async {
    await _websocket.connect();
    // handle json requests
    listen();
  }

  bool isConnected() => _websocket.isConnected();

  Future<T> _getObject<T>(path) async => switch (await get(path)) {
        Response(
          status: StatusCode(code: 200),
          body: final T buffers,
        ) =>
          buffers,
        Response(status: StatusCode(code: != 200)) =>
          throw OnDataException("Unexpected status code."),
        final other =>
          throw OnDataException("Expected body of type $T, got: $other"),
      };

  /// Get all [ApiBuffer]s from API
  Future<List<ApiBuffer>> buffers() => _getObject("/api/buffers");

  /// Get all [Line]s of a given [buffer]
  Future<List<Line>> lines(ApiBuffer buffer) =>
      _getObject("/api/buffers/${buffer.id}/lines");

  /// Get all [Nick]s of a given [buffer]
  Future<List<Nick>> nicks(ApiBuffer buffer) =>
      _getObject("/api/buffers/${buffer.id}/nicks");

  /// Get all [Hotlist]
  Future<List<Hotlist>> hotlist() => _getObject("/api/hotlist");

  /// Request a single [ApiBuffer]
  Future<ApiBuffer> buffer(IdOrName idOrName) =>
      _getObject("/api/buffers/$idOrName");

  // Future<void> sync({
  //   bool sync = true,
  //   bool nicks = false,
  //   bool input = false,
  //   Colors? colors,
  // }) async {
  //   final body = <String, dynamic>{
  //     "sync": sync,
  //     "nicks": nicks,
  //     "input": input,
  //   };
  //   if (colors case final c?) {
  //     body["colors"] = c.toString();
  //   }
  //   final r = await _websocket.post("/api/sync", body: jsonEncode(body));
  //   print(r.status.code);
  //   print(r.body);
  // }
}

typedef EventCallback = FutureOr<void> Function(Event);

enum Colors {
  ansi,
  weechat,
  strip,
}
