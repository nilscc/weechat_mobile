import 'dart:convert';

abstract interface class AuthenticationMethod {
  const AuthenticationMethod();

  // Basic authorization header, not encoded in
  String basic();

  MapEntry<String, String> authorizationHeader() => MapEntry(
        "authorization",
        "Basic ${base64.encode(utf8.encode(basic()))}",
      );
}

final class PlainAuthentication extends AuthenticationMethod {
  final String password;

  const PlainAuthentication(this.password);

  @override
  String basic() => 'plain:$password';
}
