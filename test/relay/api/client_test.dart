import 'package:flutter_test/flutter_test.dart';
import 'package:weechat/relay/api/client.dart';
import 'package:weechat/relay/api/authentication.dart';

import '../api_secrets.dart' as secrets;

void main() async {
  // TODO: mock client?!
  final client = await _connect();

  test("Get list of buffers", () async {
    final buffers = await client.buffers();
    expect(buffers, isNotEmpty);
  });

  test("Get buffer by ID", () async {
    final buffers = await client.buffers();
    expect(buffers, isNotEmpty);
    final buffer = await client.buffer(buffers.first.id);
    expect(buffer, isNotNull);
    expect(buffer!.id, equals(buffers.first.id));
  });

  test("Get lines of first buffer", () async {
    final buffers = await client.buffers();
    expect(buffers, isNotEmpty);

    final lines = await client.lines(buffers.first);
    expect(lines, isNotEmpty);
  });

  test("Get hotlist", () async {
    final hotlist = await client.hotlist();
    expect(hotlist, isNotEmpty);
    print(hotlist);
  });

  // test("Basic syncing...", () async {
  //   await client.sync(colors: Colors.strip);
  //   await Future.delayed(Duration(seconds: 30));
  // }, timeout: Timeout(Duration(minutes: 1)));
}

Future<ApiClient> _connect() async {
  final c = ApiClient(
    secrets.uri,
    PlainAuthentication(secrets.password),
  );
  await c.connect();
  assert(c.isConnected());
  return c;
}
