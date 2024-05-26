// Perform tests on live Weechat instance. Requires Weechat having the latest relay API configured and up and running. Test results could change depending on the state of the Weechat instance.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:weechat/relay/api/auth.dart';
import 'secrets.dart' as secrets;

class API {
  static final host = Uri.http('${secrets.host}:${secrets.port}', 'api');

  final client = http.Client();

  BasicAuth auth;

  API({required this.auth});

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
      host.replace(path: '${host.path}/$path'),
      body: jsonEncode(body),
      headers: <String, String>{
        'content-type': 'application/json',
      },
    );
    return _handleResponse(response);
  }

  // Perform GET request using the provided credentials
  dynamic get(final String path) async {
    final response = await client.get(
      host.replace(path: '${host.path}/$path'),
      headers: <String, String>{
        'content-type': 'application/json',
      }..addEntries([auth.header()]),
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
    final api = API(
      auth: BasicAuth(password: secrets.password, method: AuthMethod.plain),
    );
    final response = await api.get('version');
    log.d(response);
    expect(response, isNotNull);
    expect(response['relay_api_version_number'], greaterThanOrEqualTo(1));
  });

  test('SHA256 authentication', () async {
    final api = API(
      auth: BasicAuth(password: secrets.password, method: AuthMethod.sha256),
    );
    final response = await api.get('version');
    log.d(response);
    expect(response, isNotNull);
    expect(response['relay_api_version_number'], greaterThanOrEqualTo(1));
  });

  test('SHA512 authentication', () async {
    final api = API(
      auth: BasicAuth(password: secrets.password, method: AuthMethod.sha512),
    );
    final response = await api.get('version');
    log.d(response);
    expect(response, isNotNull);
    expect(response['relay_api_version_number'], greaterThanOrEqualTo(1));
  });
}
