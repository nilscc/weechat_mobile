import 'package:weechat/relay/api/client.dart';
import 'package:weechat/relay/api/authentication.dart';
import 'package:weechat/relay/api.dart';

import 'api_secrets.dart' as secrets;

void main() async {
  final client = ApiClient(
    authenticationMethod: PlainAuthentication(secrets.password),
    baseUri: secrets.uri,
  );

  final api = WeechatApi(client);

  print(await api.version());
}
