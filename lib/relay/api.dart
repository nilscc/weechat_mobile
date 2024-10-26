import 'dart:convert';

import 'package:weechat/relay/api/client.dart';

class ApiBuffer {}

class WeechatApi {
  final HttpClient client;

  WeechatApi(this.client);

  Future<Map<String, dynamic>> version() async =>
      jsonDecode(await client.read("/api/version"));

  Future<List<ApiBuffer>> buffers() async {
    await client.get("/api/buffers");
    return [];
  }

  Future<ApiBuffer?> buffer(dynamic identifier) async {
    if (!(identifier is int || identifier is String)) {
      throw "Unsupported type: ${identifier.runtimeType} (identifier = $identifier)";
    }

    final response = await client.get("/api/buffers/$identifier");
    if (response.statusCode == 200) {
      // response.body
    }

    return null; // TODO
  }
}
