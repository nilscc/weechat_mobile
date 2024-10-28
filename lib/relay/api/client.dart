import 'dart:async';
import 'dart:convert';

import 'package:weechat/relay/api/authentication.dart';
import 'package:weechat/relay/api/event.dart';
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

class ApiClient {
  final WebsocketClient _websocket;

  ApiClient(Uri baseUri, AuthenticationMethod authenticationMethod)
      : _websocket = WebsocketClient(
          baseUri: baseUri,
          authenticationMethod: authenticationMethod,
        ) {
    _websocket.onData = _onData;
  }

  void _onData(dynamic data) {
    // all data should be json decoded
    final json = jsonDecode(data);
    // check if request_id exists
    if (int.tryParse(json["request_id"]) case final id?) {
      
    }
  }

  Future<void> connect() => _websocket.connect();
  bool isConnected() => _websocket.isConnected();

  /// Helper to request a list of [T]hings.
  Future<List<T>> _jsonList<T>(String path) async {
    final response = await _websocket.get(path);

    // check for error
    if (response.status.code != 200) {
      throw UnexpectedStatus(response.status);
    }

    // parse json as list of buffers
    return (response.body as List)
        // perform `T.fromJson()`, see workaround below
        .map((m) => _callFromJson[T]!(m as Map<String, dynamic>) as T)
        .toList();
  }

  static const _callFromJson = {
    ApiBuffer: ApiBuffer.fromJson,
    Line: Line.fromJson,
    Nick: Nick.fromJson,
    Hotlist: Hotlist.fromJson,
  };

  /// Get all [ApiBuffer]s from API
  Future<List<ApiBuffer>> buffers() => _jsonList<ApiBuffer>("/api/buffers");

  /// Get all [Line]s of a given [buffer]
  Future<List<Line>> lines(ApiBuffer buffer) =>
      _jsonList<Line>("/api/buffers/${buffer.id}/lines");

  /// Get all [Nick]s of a given [buffer]
  Future<List<Nick>> nicks(ApiBuffer buffer) =>
      _jsonList("/api/buffers/${buffer.id}/nicks");

  /// Get all [Hotlist]
  Future<List<Hotlist>> hotlist() => _jsonList("/api/hotlist");

  /// Request a single [ApiBuffer]
  Future<ApiBuffer?> buffer(IdOrName idOrName) async {
    if (!(idOrName is String || idOrName is int)) {
      throw UnexpectedRequest(
        "Unexpected argument: $idOrName (type: ${idOrName.runtimeType})",
      );
    }

    final response = await _websocket.get("/api/buffers/$idOrName");
    return switch (response.body) {
      final json? => ApiBuffer.fromJson(json),
      _ => throw UnexpectedResponseBody(response.body),
    };
  }

  EventCallback? onEvent;

  Future<void> sync({
    bool sync = true,
    bool nicks = false,
    bool input = false,
    Colors? colors,
  }) async {
    final body = <String, dynamic>{
      "sync": sync,
      "nicks": nicks,
      "input": input,
    };
    if (colors case final c?) {
      body["colors"] = c.toString();
    }
    final r = await _websocket.post("/api/sync", body: jsonEncode(body));
    print(r.status.code);
    print(r.body);
  }
}

typedef EventCallback = FutureOr<void> Function(Event);

enum Colors {
  ansi,
  weechat,
  strip,
}
