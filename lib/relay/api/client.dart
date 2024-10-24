import 'package:http/http.dart' as http;
import 'package:weechat/relay/api/authentication.dart';

class ApiClient {
  final AuthenticationMethod authenticationMethod;
  final Uri baseUri;

  ApiClient({
    required this.authenticationMethod,
    required this.baseUri,
  });

  // GET request with authentication header
  Future<String> read(String path, {Map<String, String>? headers}) {
    return http.read(
      baseUri.replace(path: path),
      headers: Map.fromEntries([
        authenticationMethod.authorizationHeader(),
      ])
        ..addAll(headers ?? {}),
    );
  }
}
