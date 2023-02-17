import 'dart:async';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import 'package:weechat/widgets/home/channel_list_item.dart';
import 'package:weechat/pages/log.dart';
import 'package:weechat/pages/log/event_logger.dart';
import 'package:weechat/pages/settings.dart';
import 'package:weechat/pages/settings/config.dart';
import 'package:weechat/relay/buffer.dart';
import 'package:weechat/relay/connection.dart';
import 'package:weechat/relay/connection/status.dart';
import 'package:weechat/relay/hotlist.dart';
import 'package:weechat/relay/protocol/hdata.dart';
import 'package:weechat/widgets/channel/channel_view.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  final String title = "WeeChat Mobile";

  @override
  _HomePageState createState() => _HomePageState();

  static MaterialPageRoute route({Key? key}) =>
      MaterialPageRoute(builder: (BuildContext context) => HomePage());
}

class _HomePageState extends State<HomePage> {
  ChannelView? _channelView;

  void _disconnect(BuildContext context) async {
    final con = Provider.of<RelayConnection>(context, listen: false);

    await con.close();

    setState(() {
      _channelView = null;
    });
  }

  void _connect(BuildContext context) async {
    final cfg = Config.of(context);
    final con = Provider.of<RelayConnection>(context, listen: false);
    final log = EventLogger.of(context);

    if (con.isConnected) {
      _disconnect(context);
    } else {
      if ((cfg.hostName ?? '').isEmpty ||
          cfg.portNumber == null ||
          (cfg.relayPassword ?? '').isEmpty) {
        await Navigator.of(context).push(SettingsPage.route());
      }

      await con.connect(
        hostName: cfg.hostName!,
        portNumber: cfg.portNumber!,
        ignoreInvalidCertificate: !cfg.verifyCert!,
      );

      await con.init(cfg.relayPassword!);

      log.info('Connected relay version: ${con.relayVersion}');

      con.startPingTimer();

      await _loadCurrentGuiBuffer(con);
    }
  }

  Future<void> _loadCurrentGuiBuffer(RelayConnection connection) async {
    return connection.command(
      'hdata window:gui_current_window/buffer short_name',
      callback: (body) async {
        final h = body.objects()[0] as RelayHData;
        final o = h.objects[0];
        final bufferPtr = o.pPath[1];
        final name = o.values[0];

        final buffer = RelayBuffer(
          relayConnection: connection,
          bufferPointer: bufferPtr,
          name: name,
        );

        await buffer.sync();

        setState(() {
          _channelView = ChannelView(buffer: buffer);
        });
      },
    );
  }

  Future<List<ChannelListItem>> _loadChannelList(
      RelayConnection connection) async {
    final List<ChannelListItem> l = [];

    // https://weechat.org/files/doc/devel/weechat_plugin_api.en.html#hdata_buffer
    // https://github.com/weechat/weechat/blob/12be3b8c332c75a398f77478fd8d62304c632a1e/src/gui/gui-buffer.h#L73
    await connection.command(
      'hdata buffer:gui_buffers(*) plugin,short_name,full_name,title,nicklist_nicks_count,type',
      callback: (body) async {
        final h = body.objects()[0] as RelayHData;
        for (final o in h.objects) {
          if (o.values[1] != null) {
            l.add(ChannelListItem(
              bufferPointer: o.pPath[0],
              plugin: o.values[0],
              name: o.values[1] ?? '',
              fullName: o.values[2] ?? '',
              topic: o.values[3] ?? '',
              nickCount: o.values[4],
              key: ValueKey('ChannelListItem ${o.pPath[0]}'),
            ));
          }
        }
      },
    );

    return l;
  }

  Future<List<RelayHotlistEntry>> _loadHotList(
      RelayConnection connection) async {
    return await loadRelayHotlist(connection);
  }

  @override
  Widget build(BuildContext context) {
    final cs = RelayConnectionStatus.of(context, listen: true);
    final con = RelayConnection.of(context);

    return Scaffold(
      drawer: _channelListDrawer(context),
      onDrawerChanged: (isOpen) => _channelListDrawerChanged(con, isOpen),
      appBar: AppBar(
        title: _title(),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(LogPage.route());
            },
            icon: Icon(Feather.info),
          ),
          IconButton(
              onPressed: () {
                Navigator.of(context).push(SettingsPage.route());
              },
              icon: Icon(Icons.settings)),
        ],
      ),

      // main body
      body: SafeArea(
        top: false, // covered by app bar
        bottom: false, // covered by bottom padding of channel list
        child: _buildBody(context),
      ),

      // the connection status floating button
      floatingActionButton: cs.connected
          ? null
          : FloatingActionButton(
              onPressed: () => _connect(context),
              tooltip: 'Increment',
              backgroundColor: cs.connected ? Colors.green : Colors.red,
              child:
                  cs.connected ? Icon(Feather.log_out) : Icon(Feather.log_in),
            ),
    );
  }

  Widget _title() {
    if (_channelView != null)
      return Text(_channelView!.buffer.name);
    else
      return Text(widget.title);
  }

  Widget _buildBody(BuildContext context) {
    final cs = RelayConnectionStatus.of(context, listen: true);
    if (cs.connected && _channelView != null)
      return _channelView!;
    else
      return _showConnectionErrors(context, reason: cs.reason);
  }

  Future<Tuple2<List<ChannelListItem>, List<RelayHotlistEntry>>>?
      _channelFuture;

  void _channelListDrawerChanged(RelayConnection connection, bool isOpened) {
    setState(() {
      if (isOpened)
        _channelFuture = Future(() async {
          final l = await _loadChannelList(connection);
          final h = await _loadHotList(connection);
          return Tuple2(l, h);
        });
      else
        _channelFuture = null;
    });
  }

  Widget? _channelListDrawer(BuildContext context) {
    final con = RelayConnection.of(context, listen: false);
    if (!con.isConnected) return null;

    return Drawer(
      child: FutureBuilder(
        future: _channelFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final t = snapshot.data as Tuple2;
            final l = t.item1 as List<ChannelListItem>;
            final h = t.item2 as List<RelayHotlistEntry>;

            // convert into lookup map
            final m =
                h.asMap().map((key, value) => MapEntry(value.buffer, value));

            return ListView(
              children: l
                  .map((e) => e.build(
                        context,
                        hotlist: m[e.bufferPointer],
                        openBuffer: (context) => _openBuffer(context, e),
                      ))
                  .toList(),
            );
          } else
            return Container();
        },
      ),
    );
  }

  Future _openBuffer(
    BuildContext context,
    ChannelListItem channelListItem,
  ) async {
    final con = RelayConnection.of(context);

    if (!con.isConnected || _channelView == null) return;

    await _channelView!.buffer.desync();

    final bufferFullName = channelListItem.fullName;
    final bufferName = channelListItem.name;
    final bufferPtr = channelListItem.bufferPointer;

    // switch buffer on remote weechat
    await con.command('input core.weechat /buffer $bufferFullName');

    final buffer = RelayBuffer(
      relayConnection: con,
      bufferPointer: bufferPtr,
      name: bufferName,
    );

    await buffer.sync();

    // close the drawer
    Scaffold.of(context).closeDrawer();

    setState(() {
      _channelView = ChannelView(
        buffer: buffer,
        key: ValueKey(bufferFullName),
      );
    });
  }

  // Widget _buildChannelList(BuildContext context) {
  //   final con = RelayConnection.of(context);
  //
  //   return ReorderableListView(
  //     children: [
  //       Container(height: 5, key: UniqueKey()),
  //       ..._channelList.map((e) => e.build(
  //             context,
  //             hotlist: _hotList[e.bufferPointer],
  //             beforeBufferOpened: () => desyncHotlist(con),
  //             afterBufferClosed: () => _loadHotList(con),
  //           )),
  //       Container(height: 100, key: UniqueKey()),
  //     ],
  //     onReorder: (int oldIndex, int newIndex) async {
  //       // subtract 1 from both indexes for the first container child
  //       oldIndex -= 1;
  //       newIndex -= 1;
  //
  //       // check if both indexes are in range
  //       final l = _channelList.length;
  //       if (0 <= oldIndex && oldIndex < l && 0 <= newIndex && newIndex < l) {
  //         setState(() {
  //           _channelList.insert(newIndex, _channelList[oldIndex]);
  //           _channelList
  //               .removeAt(oldIndex < newIndex ? oldIndex : oldIndex + 1);
  //         });
  //
  //         // save new layout
  //         _saveLayout(context);
  //       }
  //     },
  //   );
  // }

  Widget _showConnectionErrors(context, {String? reason}) {
    final l = AppLocalizations.of(context)!;

    if (reason == CONNECTION_CLOSED_REMOTE)
      reason = l.errorConnectionClosedRemotely;
    else if (reason == CONNECTION_CLOSED_OS)
      reason = l.errorNotConnected;
    else if (reason == CONNECTION_TIMEOUT)
      reason = l.errorConnectionTimeout;
    else if (reason == CERTIFICATE_VERIFY_FAILED)
      reason = l.errorConnectionInvalidCertificate;

    return Container(
      padding: EdgeInsets.all(10),
      child: Container(
        padding: EdgeInsets.all(5),
        child: Text(reason ?? l.errorNotConnected),
      ),
    );
  }
}
