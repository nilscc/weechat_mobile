import 'dart:async';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:provider/provider.dart';
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
  final List<ChannelListItem> _channelList = [];
  final Map<String, RelayHotlistEntry> _hotList = {};

  ChannelView? _channelView;

  void _disconnect(BuildContext context) async {
    final con = Provider.of<RelayConnection>(context, listen: false);

    await con.close();

    setState(() {
      _channelList.clear();
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
      await _loadHotList(con);
      await _loadChannelList(con);
    }
  }

  Future<void> _loadCurrentGuiBuffer(RelayConnection connection) async {
    return connection.command(
      'hdata window:gui_current_window/buffer name',
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

  Future<void> _loadChannelList(RelayConnection connection) async {
    // https://weechat.org/files/doc/devel/weechat_plugin_api.en.html#hdata_buffer
    // https://github.com/weechat/weechat/blob/12be3b8c332c75a398f77478fd8d62304c632a1e/src/gui/gui-buffer.h#L73
    await connection.command(
      'hdata buffer:gui_buffers(*) plugin,short_name,full_name,title,nicklist_nicks_count,type',
      callback: (body) async {
        final List<ChannelListItem> l = [];

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

        // https://weechat.org/files/doc/devel/weechat_plugin_api.en.html#hdata_plugin
        // https://github.com/weechat/weechat/blob/5ae4af1549b9ec3c160b7d5d1118b3aa38d8e03d/src/plugins/weechat-plugin.h#L251

        // final pluginPointers = l.map((e) => e.plugin).toSet();
        // pluginPointers.removeWhere((e) => e == '0x0');
        // for (final s in pluginPointers) {
        //   await connection.command('hdata plugin:$s name',
        //       callback: (body) async {
        //     final h = body.objects()[0] as RelayHData;
        //     final n = h.objects[0].values[0];
        //     if (n != "irc") {
        //       l.removeWhere((e) => e.plugin == s);
        //     }
        //   });
        // }

        setState(() {
          // store channel list
          _channelList.clear();
          _channelList.addAll(l);
        });
      },
    );
  }

  Future<void> _loadHotList(RelayConnection connection) async {
    final hot = await loadRelayHotlist(connection, hotlistChanged: (e) async {
      // TODO: investigate why this won't be triggered
      print('Hotlist changed! $e');

      setState(() {
        _hotList[e.buffer] = e;
      });
    });

    setState(() {
      _hotList.clear();
      for (final e in hot) _hotList[e.buffer] = e;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = RelayConnectionStatus.of(context, listen: true);
    if (!cs.connected) _channelList.clear();

    return Scaffold(
      drawer: _channelListDrawer(context),
      appBar: AppBar(
        title: Text(widget.title),
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
      floatingActionButton: /* cs.connected ? null : */ FloatingActionButton(
        onPressed: () => _connect(context),
        tooltip: 'Increment',
        backgroundColor: cs.connected ? Colors.green : Colors.red,
        child: cs.connected ? Icon(Feather.log_out) : Icon(Feather.log_in),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final cs = RelayConnectionStatus.of(context, listen: true);
    if (cs.connected && _channelView != null)
      return _channelView!;
    else
      return _showConnectionErrors(context, reason: cs.reason);
  }

  Drawer? _channelListDrawer(BuildContext context) {
    final con = RelayConnection.of(context, listen: false);
    if (!con.isConnected) return null;

    return Drawer(
      child: ListView(
        children: [
          Container(height: 5, key: UniqueKey()),
          ..._channelList.map((e) => e.build(
                context,
                hotlist: _hotList[e.bufferPointer],
                openBuffer: (_) => _openBuffer(context, e),
                //beforeBufferOpened: () => desyncHotlist(con),
                //afterBufferClosed: () => _loadHotList(con),
              )),
          Container(height: 100, key: UniqueKey()),
        ],
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

    setState(() {
      _channelView = ChannelView(buffer: buffer);
    });

    // finally, close the drawer
    Scaffold.of(context).closeDrawer();
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

  void _saveLayout(BuildContext context) {
    //final cfg = Config.of(context);
  }
}
