import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RelayConnectionStatus extends ChangeNotifier {
  static RelayConnectionStatus of(BuildContext context, {bool listen: false}) =>
      Provider.of(context, listen: listen);

  bool _connected = false;

  bool get connected => _connected;
  set connected(bool connected) {
    print('RelayConnectionStatus.connected = $connected');
    if (_connected != connected) {
      _connected = connected;
      notifyListeners();
    }
  }
}
