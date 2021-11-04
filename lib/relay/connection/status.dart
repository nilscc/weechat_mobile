import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RelayConnectionStatus extends ChangeNotifier {
  static RelayConnectionStatus of(BuildContext context, {bool listen: false}) =>
      Provider.of(context, listen: listen);

  bool _connected = false;
  String? _reason;

  bool get connected => _connected;
  set connected(bool connected) {
    print('RelayConnectionStatus.connected = $connected');
    if (_connected != connected) {
      _connected = connected;

      // delete reason if successfully connected
      if (connected)
        _reason = null;

      notifyListeners();
    }
  }

  String? get reason => _reason;
  set reason(String? error) {
    print('RelayConnectionStatus.reason = $reason');
    if (_reason != error && error != null) {
      _reason = error;
      notifyListeners();
    }
  }
}
