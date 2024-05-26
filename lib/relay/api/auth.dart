import 'dart:convert';

import 'package:crypto/crypto.dart';

enum AuthMethod { plain, sha256, sha512 }

// Helper to convert auth method to Hash
final _hashes = <AuthMethod, Hash>{
  AuthMethod.sha256: sha256,
  AuthMethod.sha512: sha512,
};

class BasicAuth {
  final AuthMethod method;
  final String password;

  BasicAuth({
    required this.method,
    required this.password,
  });

  MapEntry<String, String> header() {
    String auth;
    if (AuthMethod.plain == method) {
      // send plaintext password
      auth = 'plain:$password';
    } else {
      auth = 'hash:${method.name}:${_encryptPw(method, password)}';
    }

    final encoded = base64.encode(utf8.encode(auth));

    // build final header entry
    return MapEntry('authorization', 'Basic $encoded');
  }

  // Encrypt (hash) password with the correct algorithm
  static String _encryptPw(final method, final password) {
    // current timestamp in seconds since epoch
    final epoch = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
    final hash =
        _hashes[method]!.convert(utf8.encode('$epoch$password')).toString();
    return '$epoch:$hash';
  }
}
