import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Config extends _ConfigBackend {
  Config({required String path}) : super(path: path);

  static Config of(BuildContext context, {bool listen = false}) =>
      Provider.of(context, listen: listen);

  String? get hostName => this['hostName'];
  set hostName(String? hostName) => this['hostName'] = hostName;

  int? get portNumber => this['portNumber'];
  set portNumber(int? portNumber) => this['portNumber'] = portNumber;

  String? get relayPassword => this['relayPassword'];
  set relayPassword(String? relayPassword) =>
      this['relayPassword'] = relayPassword;

  bool? get verifyCert => this['verifyCert'];
  set verifyCert(bool? verifyCert) =>
      this['verifyCert'] = verifyCert;

  bool get autoconnect => this['autoconnect'] ?? true;
  set autoconnect(bool autoconnect) =>
      this['autoconnect'] = autoconnect;

  bool? get uiShowCompletion => this['uiShowCompletion'];
  set uiShowCompletion(bool? uiShowCompletion) =>
      this['uiShowCompletion'] = uiShowCompletion;

  bool? get uiShowSend => this['uiShowSend'];
  set uiShowSend(bool? uiShowSend) => this['uiShowSend'] = uiShowSend;
}

class _ConfigBackend extends ChangeNotifier {
  final String path;

  _ConfigBackend({required this.path}) {
    load();
  }

  final Map<String, dynamic> values = {};

  dynamic operator [](String key) => values[key];
  void operator []=(String key, dynamic value) {
    values[key] = value;
    save();
  }

  Future<void> load() async {
    final f = File(path);
    final exists = await f.exists();
    if (exists) {
      values.addAll(json.decode(await f.readAsString()));
    }
    notifyListeners();
  }

  Future<void> save() async {
    final f = File(path);
    await f.writeAsString(json.encode(values));
  }
}
