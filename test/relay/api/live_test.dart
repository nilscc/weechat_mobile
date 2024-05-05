// Perform tests on live Weechat instance. Requires Weechat having the latest relay API configured and up and running. Test results could change depending on the state of the Weechat instance.
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'secrets.dart' as secrets;

enum AuthMethod { plain, sha256, sha512 }

// Helper to convert auth method to Hash
final _hashes = <AuthMethod, Hash>{
  AuthMethod.sha256: sha256,
  AuthMethod.sha512: sha512,
};

class API {
  static final host = Uri.http('${secrets.host}:${secrets.port}', 'api');

  final client = http.Client();

  AuthMethod authMethod;
  String password;

  API({this.authMethod = AuthMethod.sha256, required this.password});

  static dynamic _handleResponse(final http.Response response) {
    switch (response.statusCode) {
      case 200:
        {
          return jsonDecode(response.body);
        }
      default:
        {
          return; // TODO
        }
    }
  }

  static dynamic postUnauthorized(final String path, dynamic body) async {
    final response = await http.Client().post(
      host.replace(path: 'api/$path'),
      body: jsonEncode(body),
      headers: <String, String>{
        'content-type': 'application/json',
      },
    );
    return _handleResponse(response);
  }

  // Encrypt (hash) password with the correct algorithm
  static String _encryptPw(final method, final password) {
    // current timestamp in seconds since epoch
    final epoch = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
    final hash =
        _hashes[method]!.convert(utf8.encode('$epoch$password')).toString();
    return '$epoch:$hash';
  }

  // Authentication according to the spec:
  // https://specs.weechat.org/specs/2023-005-relay-http-rest-api.html#authentication
  static String _basicAuth(final String password, final AuthMethod authMethod) {
    String auth;
    if (AuthMethod.plain == authMethod) {
      // send plaintext password
      auth = 'plain:$password';
    } else {
      auth = 'hash:${authMethod.name}:${_encryptPw(authMethod, password)}';
    }

    final encoded = base64.encode(utf8.encode(auth));
    return 'Basic $encoded';
  }

  // Perform GET request using the provided credentials
  dynamic get(final String path) async {
    final response = await client.get(
      host.replace(path: 'api/$path'),
      headers: <String, String>{
        'content-type': 'application/json',
        'authorization': _basicAuth(password, authMethod),
      },
    );
    return _handleResponse(response);
  }
}

void main() async {
  final log = Logger();

  test('Handshake', () async {
    final response = await API.postUnauthorized('handshake', {
      'password_hash_algo': ['plain'],
    });
    log.d(response);
    expect(response, isNotNull);
    expect(response['password_hash_algo'], equals('plain'));
    expect(response['password_hash_iterations'], equals(100000));
    expect(response['totp'], isFalse);
  });

  // Test authentication

  test('Plain authentication', () async {
    final api = API(password: secrets.password, authMethod: AuthMethod.plain);
    final response = await api.get('version');
    log.d(response);
    expect(response, isNotNull);
    expect(response['relay_api_version_number'], greaterThanOrEqualTo(1));
  });

  test('SHA256 authentication', () async {
    final api = API(password: secrets.password, authMethod: AuthMethod.sha256);
    final response = await api.get('version');
    log.d(response);
    expect(response, isNotNull);
    expect(response['relay_api_version_number'], greaterThanOrEqualTo(1));
  });

  test('SHA512 authentication', () async {
    final api = API(password: secrets.password, authMethod: AuthMethod.sha512);
    final response = await api.get('version');
    log.d(response);
    expect(response, isNotNull);
    expect(response['relay_api_version_number'], greaterThanOrEqualTo(1));
  });
}
