import 'dart:io';

import 'package:flutter/material.dart';
import 'package:weechat/pages/settings.dart';
import 'package:weechat/pages/settings/config.dart';
import 'package:weechat/relay/connection.dart';
import 'package:weechat/relay/hdata.dart';
import 'package:weechat/relay/parser.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  RelayConnection _connection = RelayConnection();

  void _connect(BuildContext context) async {
    final cfg = Config.of(context);

    if (_connection.isConnected()) {
      await _connection.close();
      setState(() {});
    } else {
      await _connection.connect(
        hostName: cfg.hostName!,
        portNumber: cfg.portNumber!,
      );

      await _connection.handshake();
      await _connection.init(cfg.relayPassword!);

      //await _connection.test();
      await _connection.command(
        'buffers',
        'hdata buffer:gui_buffers(*) number,full_name',
        callback: (body) async {
          final h = body.objects()[0] as RelayHData;
          for (var o in h.objects) {
            print('${o.pPath} - ${o.values}');
          }
        },
      );

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => SettingsPage()));
              },
              icon: Icon(Icons.settings)),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _connect(context),
        tooltip: 'Increment',
        child: Icon(_connection.isConnected()
            ? Icons.stop_outlined
            : Icons.play_arrow_outlined),
      ),
    );
  }
}
