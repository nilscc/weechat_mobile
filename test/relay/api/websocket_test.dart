import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:weechat/relay/api/websocket.dart';
import 'package:weechat/relay/api/authentication.dart';

import '../api_secrets.dart' as secrets;

void main() async {
  // websocket test
  _wsConnectTest();
  _wsPingTest();
  _wsGetVersion();
}

Future<WebsocketClient> _connect({Duration? pingInterval}) async {
  final client = WebsocketClient(
    baseUri: secrets.uri.replace(scheme: "wss"),
    authenticationMethod: PlainAuthentication(secrets.password),
  );
  expect(client.isConnected(), isFalse);

  await client.connect(pingInterval: pingInterval);
  expect(client.webSocket, isNotNull);
  expect(client.webSocket?.readyState, WebSocket.open);
  expect(client.isConnected(), isTrue);

  return client;
}

void _wsConnectTest() => test(
      "Create new web socket and check open status",
      () async => await _connect(),
    );

void _wsPingTest() => test(
      "Set ping interval and check if connection stays alive",
      () async {
        // set a really quick ping interval
        final client = await _connect(pingInterval: Duration(seconds: 1));

        // wait 5 times that duration
        await Future.delayed(Duration(seconds: 5));

        // connection should still be fine.
        expect(client.webSocket?.readyState, WebSocket.open);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

void _wsGetVersion() => test(
      "Get version via websocket",
      () async {
        // final c = await _connect();
        // await c.get("/api/version", callback: (status, body) async {
        //   expect(status.code, 200);
        //   expect(body, isNotNull);
        //   return true;
        // });
      },
    );
