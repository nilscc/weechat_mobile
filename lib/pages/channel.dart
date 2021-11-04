import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:weechat/pages/channel/lines.dart';
import 'package:weechat/relay/buffer.dart';
import 'package:weechat/relay/connection.dart';
import 'package:weechat/relay/connection/status.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChannelPage extends StatefulWidget {
  final RelayBuffer buffer;

  ChannelPage({
    required this.buffer,
  });

  @override
  _ChannelPageState createState() => _ChannelPageState();

  static MaterialPageRoute route({
    required RelayBuffer buffer,
  }) =>
      MaterialPageRoute(
        builder: (context) => ChannelPage(
          buffer: buffer,
        ),
      );
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
          child: Text(widget.buffer.name),
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

  Widget _linesWidget(BuildContext context) => ChangeNotifierProvider.value(
        value: widget.buffer,
        child: ChannelLines(),
      );

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
