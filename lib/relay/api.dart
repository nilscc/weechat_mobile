import 'dart:convert';

import 'package:weechat/relay/api/client.dart';

class WeechatApi {
  final ApiClient client;

  WeechatApi(this.client);

  Future<Map<String, dynamic>> version() async =>
      jsonDecode(await client.read("/api/version"));
}
