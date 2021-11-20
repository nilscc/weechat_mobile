import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:provider/provider.dart';
import 'package:weechat/pages/channel/lines.dart';
import 'package:weechat/pages/home.dart';
import 'package:weechat/pages/settings/config.dart';
import 'package:weechat/relay/buffer.dart';
import 'package:weechat/relay/completion.dart';
import 'package:weechat/relay/connection.dart';
import 'package:weechat/relay/connection/status.dart';
//import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    if (!_status.connected)
      Navigator.of(context).pushAndRemoveUntil(
        HomePage.route(),
        (route) => false, // remove all previous routes
      );
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
          SafeArea(
            bottom: true,
            child: _inputWidget(context),
          ),
        ],
      ),
    );
  }

  final _linesController = ScrollController();

  Widget _linesWidget(BuildContext context) => ChangeNotifierProvider.value(
        value: widget.buffer,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: ChannelLines(scrollController: _linesController),
        ),
      );

  final _inputController = TextEditingController();

  RelayCompletion? _completion;

  void _send(RelayConnection con) async {
    final text = _inputController.text;
    if (text.isNotEmpty) {
      await con.command('input ${widget.buffer.bufferPointer} $text');
      _inputController.text = '';
      _linesController.jumpTo(0);
    }
  }

  Widget _inputWidget(BuildContext context) {
    //final loc = AppLocalizations.of(context)!;
    final con = Provider.of<RelayConnection>(context);
    final cfg = Config.of(context);

    return Card(
      margin: EdgeInsets.all(10),
      child: Container(
        padding: EdgeInsets.only(left: 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.send,
                controller: _inputController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                ),
                onChanged: (text) {
                  _completion = null;
                },
                onEditingComplete: () => _send(con),
              ),
            ),
            if (cfg.uiShowCompletion ?? true)
              Container(
                padding: EdgeInsets.zero,
                child: IconButton(
                  icon: Icon(Icons.keyboard_tab),
                  onPressed: () async {
                    if (_completion == null)
                      _completion = await RelayCompletion.load(
                          con,
                          widget.buffer.bufferPointer,
                          _inputController.text,
                          _inputController.selection.base.offset);

                    if (_completion != null) {
                      final n = _completion!.next();
                      _inputController.text = n.item1;
                      _inputController.selection = TextSelection(
                        baseOffset: n.item2,
                        extentOffset: n.item2,
                      );
                    }
                  },
                ),
              ),
            if (cfg.uiShowSend ?? false)
              Container(
                child: IconButton(
                  icon: Icon(Feather.arrow_up),
                  onPressed: () => _send(con),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
