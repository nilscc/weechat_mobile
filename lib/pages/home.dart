import 'dart:async';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:provider/provider.dart';
import 'package:weechat/pages/home/channel_list_item.dart';
import 'package:weechat/pages/log.dart';
import 'package:weechat/pages/log/event_logger.dart';
import 'package:weechat/pages/settings.dart';
import 'package:weechat/pages/settings/config.dart';
import 'package:weechat/relay/connection.dart';
import 'package:weechat/relay/connection/status.dart';
import 'package:weechat/relay/hotlist.dart';
import 'package:weechat/relay/protocol/hdata.dart';

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

  void _connect(BuildContext context) async {
    final cfg = Config.of(context);
    final con = Provider.of<RelayConnection>(context, listen: false);
    final log = EventLogger.of(context);

    if (con.isConnected) {
      await con.close();
      setState(() {
        _channelList.clear();
      });
    } else {
      if ((cfg.hostName ?? '').isEmpty ||
          cfg.portNumber == null ||
          (cfg.relayPassword ?? '').isEmpty) {
        await Navigator.of(context).push(SettingsPage.route());
      }

      await con.connect(
        hostName: cfg.hostName!,
        portNumber: cfg.portNumber!,
      );

      await con.handshake();
      await con.init(cfg.relayPassword!);

      log.info('Connected relay version: ${con.relayVersion}');

      con.startPingTimer();

      await _loadChannelList(context);
      await _loadHotList(context);

      // change buffer of remote if configured
      if (cfg.changeBufferOnConnect == true)
        await con.command(
          'input core.weechat /buffer weechat',
        );
    }
  }

  Future<void> _loadChannelList(BuildContext context) async {
    final con = Provider.of<RelayConnection>(context, listen: false);

    // https://weechat.org/files/doc/devel/weechat_plugin_api.en.html#hdata_buffer
    // https://github.com/weechat/weechat/blob/12be3b8c332c75a398f77478fd8d62304c632a1e/src/gui/gui-buffer.h#L73
    await con.command(
      'hdata buffer:gui_buffers(*) plugin,short_name,title,nicklist_nicks_count,type',
      callback: (body) async {
        final List<ChannelListItem> l = [];

        final h = body.objects()[0] as RelayHData;
        for (final o in h.objects) {
          if (o.values[1] != null) {
            l.add(ChannelListItem(
              bufferPointer: o.pPath[0],
              plugin: o.values[0],
              name: o.values[1] ?? '',
              topic: o.values[2] ?? '',
              nickCount: o.values[3],
              key: ValueKey('ChannelListItem ${o.pPath[0]}'),
            ));
          }
        }

        // https://weechat.org/files/doc/devel/weechat_plugin_api.en.html#hdata_plugin
        // https://github.com/weechat/weechat/blob/5ae4af1549b9ec3c160b7d5d1118b3aa38d8e03d/src/plugins/weechat-plugin.h#L251

        final pluginPointers = l.map((e) => e.plugin).toSet();
        pluginPointers.removeWhere((e) => e == '0x0');
        for (final s in pluginPointers) {
          await con.command('hdata plugin:$s name', callback: (body) async {
            final h = body.objects()[0] as RelayHData;
            final n = h.objects[0].values[0];
            if (n != "irc") {
              l.removeWhere((e) => e.plugin == s);
            }
          });
        }

        setState(() {
          // store channel list
          _channelList.clear();
          _channelList.addAll(l);
        });
      },
    );
  }

  Future<void> _loadHotList(BuildContext context) async {
    final con = RelayConnection.of(context);

    final hot = await loadRelayHotlist(con, hotlistChanged: (e) async {
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
      body: _buildBody(context),

      // the connection status floating button
      floatingActionButton: FloatingActionButton(
        onPressed: () => _connect(context),
        tooltip: 'Increment',
        backgroundColor: cs.connected ? Colors.green : Colors.red,
        child: cs.connected ? Icon(Feather.log_out) : Icon(Feather.log_in),
      ),
    );
  }

  Future<void> refresh(BuildContext context) async {
    final log = EventLogger.of(context);
    log.info('Refresh channel list.');

    await _loadHotList(context);
  }

  Widget _buildBody(BuildContext context) {
    final cs = RelayConnectionStatus.of(context, listen: true);
    if (cs.connected)
      return RefreshIndicator(
        onRefresh: () => refresh(context),
        child: _buildChannelList(context),
      );
    else
      return _showConnectionErrors(context, reason: cs.reason);
  }

  Widget _buildChannelList(BuildContext context) {
    return ReorderableListView(
      children: [
        Container(height: 5, key: UniqueKey()),
        ..._channelList.map((e) => e.build(
              context,
              hotlist: _hotList[e.bufferPointer],
              onBufferRouteClosed: () async {
                await _loadHotList(context);
              },
            )),
        Container(height: 100, key: UniqueKey()),
      ],
      onReorder: (int oldIndex, int newIndex) async {
        // subtract 1 from both indexes for the first container child
        oldIndex -= 1;
        newIndex -= 1;

        // check if both indexes are in range
        final l = _channelList.length;
        if (0 <= oldIndex && oldIndex < l && 0 <= newIndex && newIndex < l) {
          setState(() {
            _channelList.insert(newIndex, _channelList[oldIndex]);
            _channelList
                .removeAt(oldIndex < newIndex ? oldIndex : oldIndex + 1);
          });

          // save new layout
          _saveLayout(context);
        }
      },
    );
  }

  Widget _showConnectionErrors(context, {String? reason}) {
    final l = AppLocalizations.of(context)!;

    if (reason == CONNECTION_CLOSED_REMOTE)
      reason = l.errorConnectionClosedRemotely;
    else if (reason == CONNECTION_CLOSED_OS)
      reason = l.errorNotConnected;
    else if (reason == CONNECTION_TIMEOUT) reason = l.errorConnectionTimeout;

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
