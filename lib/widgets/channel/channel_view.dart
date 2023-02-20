import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:provider/provider.dart';
import 'package:weechat/widgets/channel/lines.dart';
import 'package:weechat/pages/settings/config.dart';
import 'package:weechat/relay/buffer.dart';
import 'package:weechat/relay/completion.dart';
import 'package:weechat/relay/connection.dart';

class ChannelView extends StatefulWidget {
  final RelayBuffer buffer;

  const ChannelView({required this.buffer, super.key});

  @override
  State<StatefulWidget> createState() => _ChannelViewState();
}

class _ChannelViewState extends State<ChannelView> {
  final _inputController = TextEditingController();

  late final FocusNode _inputFocusNode;

  final _linesController = ScrollController();

  RelayCompletion? _completion;

  @override
  void initState() {
    super.initState();

    // handle tab events in focus node of input field
    _inputFocusNode = FocusNode(
      debugLabel: "_inputFocusNode",
      onKey: (node, event) {
        if (event is RawKeyDownEvent && event.logicalKey.keyLabel == 'Tab') {
          final con = RelayConnection.of(node.context!);
          _complete(con);
          return KeyEventResult.handled;
        } else {
          return KeyEventResult.ignored;
        }
      },
    );

    // automatically focus on the input field when opening a new channel
    _inputFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false, // covered by app bar
        child: Column(
          children: [
            Expanded(flex: 1, child: _linesWidget(context)),
            _inputWidget(context),
          ],
        ),
      );

  void resume() {}

  Widget _linesWidget(BuildContext context) => ChangeNotifierProvider.value(
        value: widget.buffer,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ChannelLines(scrollController: _linesController),
        ),
      );

  void _send(RelayConnection con) async {
    final text = _inputController.text;
    if (text.isNotEmpty) {
      await con.command('input ${widget.buffer.bufferPointer} $text');
      _inputController.text = '';
      _linesController.jumpTo(0);
    }
  }

  void _complete(RelayConnection connection) async {
    _completion ??= await RelayCompletion.load(
        connection,
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
  }

  Widget _inputWidget(BuildContext context) {
    //final loc = AppLocalizations.of(context)!;
    final con = Provider.of<RelayConnection>(context);
    final cfg = Config.of(context);

    return Card(
      margin: const EdgeInsets.all(10),
      child: Container(
        padding: const EdgeInsets.only(left: 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.send,
                controller: _inputController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
                onChanged: (text) {
                  _completion = null;
                },
                onEditingComplete: () => _send(con),
                focusNode: _inputFocusNode,
              ),
            ),
            if (cfg.uiShowCompletion ?? true)
              Container(
                padding: EdgeInsets.zero,
                child: IconButton(
                  icon: const Icon(Icons.keyboard_tab),
                  onPressed: () => _complete(con),
                ),
              ),
            if (cfg.uiShowSend ?? false)
              IconButton(
                icon: const Icon(Feather.arrow_up),
                onPressed: () => _send(con),
              ),
          ],
        ),
      ),
    );
  }
}
