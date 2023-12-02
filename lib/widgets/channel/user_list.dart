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
          if (!snapshot.hasData) {
            return _loading();
          } else if (snapshot.data == null) {
            return _failed();
          } else {
            return _userList(context, snapshot.data!);
          }
        });
  }

  Widget _loading() => Container();
  Widget _failed() => Container();

  Widget _userList(BuildContext context, List<NicklistData> nicks) {
    return ListView(
      children: nicks.map((nick) => _userWidget(context, nick)).toList(),
    );
  }

  Widget _userWidget(BuildContext context, NicklistData nick) {
    return ListTile(
      title: Text("${nick.prefix}${nick.name}"),
    );
  }
}
