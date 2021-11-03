import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:weechat/pages/channel/line.dart';
import 'package:weechat/relay/colors.dart';
import 'package:weechat/relay/connection.dart';
import 'package:weechat/relay/connection/status.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:weechat/relay/hdata.dart';

class ChannelPage extends StatefulWidget {
  final String bufferPointer, name;

  ChannelPage({
    required this.bufferPointer,
    required this.name,
  });

  @override
  _ChannelPageState createState() => _ChannelPageState();

  static MaterialPageRoute route({
    required String bufferPointer,
    required String name,
  }) =>
      MaterialPageRoute(
          builder: (context) => ChannelPage(
                bufferPointer: bufferPointer,
                name: name,
              ));
}

class _ChannelPageState extends State<ChannelPage> {
  late RelayConnectionStatus _status;

  void _closeOnDisconnect() {
    if (!_status.connected) Navigator.of(context).pop();
  }

  @override
  void initState() {
    _status = Provider.of<RelayConnectionStatus>(context, listen: false);
    _status.addListener(_closeOnDisconnect);
    super.initState();
  }

  @override
  void dispose() {
    _status.removeListener(_closeOnDisconnect);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Provider.of<RelayConnection>(context);
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            print('Tap!');
          },
          child: Text(widget.name),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _linesWidget(context), flex: 1),
          Container(
            child: _inputWidget(context),
          ),
        ],
      ),
    );
  }

  Widget _linesWidget(BuildContext context) {
    final c = Provider.of<RelayConnection>(context);
    final comp = Completer();

    c.command(
      'buffer_lines',
      'hdata buffer:${widget.bufferPointer}/own_lines/last_line(-30)/data date,prefix,message',
      callback: (body) async {
        final List<ChannelLine> l = [];
        final objs = body.objects();
        for (final obj in objs) {
          for (int i = 0; i < obj.count; ++i) {
            final o = obj.objects[i];
            final d = DateTime.fromMillisecondsSinceEpoch(o.values[0] * 1000);
            final p = stripColors(o.values[1]);
            final m = stripColors(o.values[2]);
            l.insert(
                0,
                ChannelLine(
                  lineDataPointer: o.pPath[3],
                  date: d,
                  prefix: p,
                  message: m,
                ));
          }
        }
        comp.complete(l);
      },
    );

    return FutureBuilder(
        future: comp.future,
        builder: (context, snapshot) => ListView(
              children: [
                if (snapshot.hasData)
                  ...(snapshot.data as List<ChannelLine>)
                      .map((e) => e.build(context)),
              ],
            ));
  }

  TextEditingController _inputController = TextEditingController();

  Widget _inputWidget(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Card(
      margin: EdgeInsets.all(10),
      child: Container(
        padding: EdgeInsets.only(left: 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.text,
                controller: _inputController,
                decoration: InputDecoration.collapsed(
                  hintText: loc.channelInputPlaceholder,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.zero,
              child: IconButton(
                icon: Icon(Icons.keyboard_tab),
                onPressed: () {},
              ),
            ),
            Container(
              padding: EdgeInsets.zero,
              child: IconButton(
                icon: Icon(Icons.arrow_upward),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
