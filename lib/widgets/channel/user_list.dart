import 'package:flutter/material.dart';
import 'package:weechat/relay/nicklist.dart';

class UserListWidget extends StatefulWidget {
  final RelayBufferNicklist nicklist;

  const UserListWidget({
    required this.nicklist,
    super.key,
  });

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

Future? _request;

class _State extends State<UserListWidget> {
  RelayBufferNicklist get nicklist => widget.nicklist;

  _State();

  @override
  Widget build(BuildContext context) {
    // request nicklist from server
    _request ??= nicklist.load();

    return FutureBuilder(
        future: _request,
        builder: (context, snapshot) {
          return ListView(
            children: const [],
          );
        });
  }
}
