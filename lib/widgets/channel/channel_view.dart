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
  final FocusNode inputFocusNode;

  ChannelView({super.key, inputFocusNode})
      : inputFocusNode = inputFocusNode ?? FocusNode();

  @override
  State<StatefulWidget> createState() => _ChannelViewState();
}

class _ChannelViewState extends State<ChannelView> {
  final _inputController = TextEditingController();

  final _linesController = ScrollController();

  RelayCompletion? _completion;

  @override
  void initState() {
    super.initState();

    widget.inputFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent && event.logicalKey.keyLabel == 'Tab') {
        final con = RelayConnection.of(node.context!);
        final buffer = Provider.of<RelayBuffer>(node.context!);
        _complete(con, buffer);
        return KeyEventResult.handled;
      } else {
        return KeyEventResult.ignored;
      }
    };

    // automatically focus on the input field when opening a new channel
    widget.inputFocusNode.requestFocus();
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

  Widget _linesWidget(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: ChannelLines(scrollController: _linesController),
      );

  void _send(RelayConnection con, RelayBuffer buffer) async {
    final text = _inputController.text;
    if (text.isNotEmpty) {
      await con.command('input ${buffer.bufferPointer} $text');
      _inputController.text = '';
      _linesController.jumpTo(0);
    }
  }

  void _complete(RelayConnection connection, RelayBuffer buffer) async {
    _completion ??= await RelayCompletion.load(
      connection,
      buffer.bufferPointer,
      _inputController.text,
      _inputController.selection.base.offset,
    );

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
    final con = Provider.of<RelayConnection>(context);
    final cfg = Config.of(context);

    final buffer = Provider.of<RelayBuffer>(context, listen: true);

    return Card(
      margin: const EdgeInsets.all(10),
      child: Container(
        padding: const EdgeInsets.only(left: 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                maxLines: null,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.send,
                controller: _inputController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
                onChanged: (text) {
                  _completion = null;
                },
                onEditingComplete:
                    buffer.active ? () => _send(con, buffer) : null,
                focusNode: widget.inputFocusNode,
              ),
            ),
            if (cfg.uiShowCompletion ?? true)
              Container(
                padding: EdgeInsets.zero,
                child: IconButton(
                  icon: const Icon(Icons.keyboard_tab),
                  onPressed:
                      buffer.active ? () => _complete(con, buffer) : null,
                ),
              ),
            if (cfg.uiShowSend ?? false)
              IconButton(
                icon: const Icon(Feather.arrow_up),
                onPressed: () => _send(con, buffer),
              ),
          ],
        ),
      ),
    );
  }
}
