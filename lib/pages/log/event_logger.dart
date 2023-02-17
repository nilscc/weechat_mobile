// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

enum LogType {
  INFO,
  WARNING,
  ERROR,
}

class EventLogger extends ChangeNotifier {
  final List<Tuple3<DateTime, LogType, String>> _messages = [];

  List<Tuple3<DateTime, LogType, String>> get messages => _messages;

  static EventLogger of(BuildContext context, {bool listen = false}) =>
      Provider.of<EventLogger>(context, listen: listen);

  void log(LogType type, String message, {DateTime? dateTime}) {
    // ignore: avoid_print
    print('[$type] $message');
    _messages.add(Tuple3(dateTime ?? DateTime.now(), type, message));
    notifyListeners();
  }

  void info(String message) => log(LogType.INFO, message);
  void warning(String message) => log(LogType.WARNING, message);
  void error(String message) => log(LogType.ERROR, message);
}
