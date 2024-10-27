import 'package:flutter_test/flutter_test.dart';
import 'package:weechat/relay/api/client.dart';
import 'package:weechat/relay/api/authentication.dart';

import '../api_secrets.dart' as secrets;

void main() async {
  final client = await _connect();

  _listBuffers(client);
  _bufferById(client);
  _lines(client);
}

Future<ApiClient> _connect() async {
  final c = await ApiClient(
    secrets.uri,
    PlainAuthentication(secrets.password),
  );
  await c.connect();
  assert(c.isConnected());
  return c;
}

void _listBuffers(final client) => test("Get list of buffers", () async {
      final buffers = await client.buffers();
      expect(buffers, isNotEmpty);
    });

void _bufferById(final client) => test("Get buffer by ID", () async {
      final buffers = await client.buffers();
      expect(buffers, isNotEmpty);
      final buffer = await client.buffer(buffers.first.id);
      expect(buffer, isNotNull);
      expect(buffer.id, equals(buffers.first.id));
    });

void _lines(final client) => test("Get lines of first buffer", () async {
      final buffers = await client.buffers();
      expect(buffers, isNotEmpty);

      final lines = await client.lines(buffers.first);
      expect(lines, isNotEmpty);
    });
