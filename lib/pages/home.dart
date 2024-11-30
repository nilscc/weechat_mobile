import 'dart:async';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';
import 'package:weechat/relay/nicklist.dart';
import 'package:weechat/widgets/channel/user_list.dart';
import 'package:weechat/widgets/home/channel_list_item.dart';
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
  const HomePage({super.key});

  final String title = "WeeChat Mobile";

  @override
  State<HomePage> createState() => _HomePageState();

  static MaterialPageRoute route({Key? key}) =>
      MaterialPageRoute(builder: (BuildContext context) => const HomePage());
}

class _GuiCurrentWindowBuffer {
  final String bufferPointer;
  final String shortName;
  final String name;
  final String fullName;

  _GuiCurrentWindowBuffer({
    required this.bufferPointer,
    required this.shortName,
    required this.name,
    required this.fullName,
  });

  RelayBuffer toRelayBuffer(RelayConnection relayConnection) => RelayBuffer(
        relayConnection: relayConnection,
        bufferPointer: bufferPointer,
        name: shortName,
      );

  static Future<_GuiCurrentWindowBuffer?> load(
      RelayConnection relayConnection) async {
    return relayConnection.command(
      'hdata window:gui_current_window/buffer full_name,name,short_name',
      callback: (body) {
        final h = body.objects()[0] as RelayHData;
        final o = h.objects[0];

        final bufferPtr = o.pPath[1];
        final fullName = o.value('full_name');
        final name = o.value('name');
        final shortName = o.value('short_name');

        return _GuiCurrentWindowBuffer(
          bufferPointer: bufferPtr,
          shortName: shortName ?? name,
          name: name,
          fullName: fullName,
        );
      },
    );
  }
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  RelayBuffer? _relayBuffer;
  EventLogger? _eventLogger;
  Config? _config;
  RelayConnection? _relayConnection;

  // UI control
  final _inputFocusNode = FocusNode();
  bool _inputHadFocus = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    _eventLogger?.debug('Lifecycle state: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        {
          return _resume();
        }
      case AppLifecycleState.paused:
        {
          return _suspend();
        }
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        {
          break;
        }
      case AppLifecycleState.hidden:
        {
          break;
        }
    }
  }

  bool _suspended = false;
  Future<void> _suspend() async {
    setState(() {
      _suspended = true;
      _inputHadFocus = _inputFocusNode.hasFocus;
    });
    await _relayBuffer?.suspend();
    await _disconnect();
  }

  Future<void> _resume() async {
    if (_relayConnection == null || _config == null) {
      return setState(() {
        _suspended = false;
      });
    }

    // check if we're already connected or if we don't have autoconnect
    // configured
    if (_suspended && _connectionConfigured(_config!) && _config!.autoconnect) {
      await _connect();

      // check if weechat gui has still the same buffer opened
      final wb = await _GuiCurrentWindowBuffer.load(_relayConnection!);

      // check if current and previous buffer pointer still are the same.
      // this will prevent not only issues when switching buffers in the UI, but also if
      // e.g. the weechat instance was upgraded to a new software version and prevents
      // accessing (and crashing weechat) illegal pointer addresses.
      if (wb != null) {
        if (wb.bufferPointer == _relayBuffer?.bufferPointer) {
          await _relayBuffer?.resume();
          if (_inputHadFocus) {
            _inputFocusNode.requestFocus();
          }
        } else {
          setState(() {
            _relayBuffer = wb.toRelayBuffer(_relayConnection!);
          });
          await _relayBuffer!.sync();
        }
      } else {
        _disconnect();
        setState(() {
          _relayBuffer = null;
        });
      }

      // unset suspended state in any case
      setState(() {
        _suspended = false;
      });
    }
  }

  static bool _connectionConfigured(Config cfg) =>
      (cfg.hostName ?? '').isNotEmpty &&
      cfg.portNumber != null &&
      (cfg.relayPassword ?? '').isNotEmpty;

  Future<void> _connect() async {
    if (_relayConnection == null ||
        _config == null ||
        !_connectionConfigured(_config!)) {
      _eventLogger
          ?.error('Home._connect() called without connection or config');
      return;
    }

    await _relayConnection!.connect(
      hostName: _config!.hostName!,
      portNumber: _config!.portNumber!,
      ignoreInvalidCertificate: !(_config!.verifyCert ?? true),
    );

    await _relayConnection!.init(_config!.relayPassword!);

    _eventLogger
        ?.info('Connected relay version: ${_relayConnection!.relayVersion}');

    _relayConnection!.startPingTimer();
  }

  Future<void> _disconnect() async {
    await _relayConnection?.close();
  }

  Future<void> _toggleConnect(BuildContext context) async {
    final con = Provider.of<RelayConnection>(context, listen: false);

    if (con.isConnected) {
      await _disconnect();
      setState(() {
        _relayBuffer = null;
      });
    } else {
      if (!_connectionConfigured(_config!)) {
        await Navigator.of(context).push(SettingsPage.route());
      }
      await _connect();
      await _loadCurrentGuiBuffer();
    }
  }

  Future<void> _loadCurrentGuiBuffer() async {
    // require connection
    if (_relayConnection == null) {
      return;
    }

    // require window buffer
    final wb = await _GuiCurrentWindowBuffer.load(_relayConnection!);
    if (wb == null) {
      return;
    }

    // connect and sync buffer
    final buffer = wb.toRelayBuffer(_relayConnection!);
    await buffer.sync();

    setState(() {
      _relayBuffer = buffer;
    });
  }

  Future<List<ChannelListItem>> _loadChannelList(
      RelayConnection connection) async {
    final List<ChannelListItem> l = [];

    // https://weechat.org/files/doc/devel/weechat_plugin_api.en.html#hdata_buffer
    // https://github.com/weechat/weechat/blob/12be3b8c332c75a398f77478fd8d62304c632a1e/src/gui/gui-buffer.h#L73
    await connection.command(
      'hdata buffer:gui_buffers(*) plugin,short_name,full_name,title,nicklist_nicks_count',
      callback: (body) async {
        final h = body.objects()[0] as RelayHData;
        for (final o in h.objects) {
          if (o.value('short_name') != null) {
            l.add(ChannelListItem(
              bufferPointer: o.pPath[0],
              plugin: o.value('plugin'),
              name: o.value('short_name'),
              fullName: o.value('full_name') ?? '',
              topic: o.value('title') ?? '',
              nickCount: o.value('nicklist_nicks_count'),
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

  Future<void> _autoConnect() async {
    if (_config!.autoconnect &&
        _connectionConfigured(_config!) &&
        !_relayConnection!.connectionStatus.connected) {
      await _connect();
      if (_relayBuffer == null) {
        await _loadCurrentGuiBuffer();
      }
    }
  }

  void _init(BuildContext context) {
    _eventLogger ??= EventLogger.of(context);
    _relayConnection ??= RelayConnection.of(context);

    // wait for config being loaded and then auto connect
    if (_config == null) {
      _config = Config.of(context);
      _config!.addListener(_autoConnect);
    }
  }

  @override
  Widget build(BuildContext context) {
    _init(context);

    // get current connection status
    final cs = RelayConnectionStatus.of(context, listen: true);

    return Scaffold(
      drawer: _channelListDrawer(context),
      onDrawerChanged: (isOpen) {
        if (_relayConnection != null) {
          _channelListDrawerChanged(_relayConnection!, isOpen);
        }
      },
      endDrawer: _userListDrawer(context),
      appBar: AppBar(
        title: _title(),
        actions: [
          // show users button if connected
          if (cs.connected)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.group),
                onPressed: () => _toggleUserList(context),
              ),
            ),
          // settings button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(SettingsPage.route());
            },
          )
        ],
      ),

      // main body
      body: SafeArea(
        top: false, // covered by app bar
        bottom: false, // covered by bottom padding of channel list
        child: _buildBody(context),
      ),

      // the connection status floating button
      floatingActionButton: (cs.connected || _suspended)
          ? null
          : FloatingActionButton(
              onPressed: () => _toggleConnect(context),
              tooltip: 'Increment',
              backgroundColor: cs.connected ? Colors.green : Colors.red,
              child: cs.connected
                  ? const Icon(Feather.log_out)
                  : const Icon(Feather.log_in),
            ),
    );
  }

  Widget _title() {
    return Text(_relayBuffer?.name ?? widget.title);
  }

  Widget _buildBody(BuildContext context) {
    final cs = RelayConnectionStatus.of(context, listen: true);
    if ((cs.connected || _suspended) && _relayBuffer != null) {
      return ChangeNotifierProvider.value(
        value: _relayBuffer,
        child: ChannelView(
          inputFocusNode: _inputFocusNode,
          key: ValueKey('ChannelView(buffer: ${_relayBuffer?.bufferPointer})'),
        ),
      );
    } else {
      return _showConnectionErrors(context, reason: cs.reason);
    }
  }

  Future<Tuple2<List<ChannelListItem>, List<RelayHotlistEntry>>>?
      _channelFuture;

  void _channelListDrawerChanged(RelayConnection connection, bool isOpened) {
    setState(() {
      if (isOpened) {
        _channelFuture = Future(() async {
          final l = await _loadChannelList(connection);
          final h = await _loadHotList(connection);
          return Tuple2(l, h);
        });
      } else {
        _channelFuture = null;
      }
    });
  }

  Widget? _userListDrawer(BuildContext context) {
    if (_relayBuffer != null) {
      return Drawer(
        child: UserListWidget(
          nicklist: RelayBufferNicklist(
            bufferId: _relayBuffer!.bufferPointer,
            connection: _relayBuffer!.relayConnection,
          ),
        ),
      );
    } else {
      return const Drawer();
    }
  }

  void _toggleUserList(BuildContext context) {
    final scaff = Scaffold.of(context);
    if (scaff.isEndDrawerOpen) {
      scaff.closeEndDrawer();
    } else {
      scaff.openEndDrawer();
    }
  }

  Widget? _channelListDrawer(BuildContext context) {
    final con = RelayConnection.of(context, listen: false);
    if (!con.isConnected) return null;

    return Drawer(
      child: FutureBuilder(
        future: _channelFuture,
        builder: (context, snapshot) {
          final scaffoldState = Scaffold.of(context);
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
                        openBuffer: (context) =>
                            _openBuffer(scaffoldState, con, e),
                      ))
                  .toList(),
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }

  Future _openBuffer(
    ScaffoldState scaffoldState,
    RelayConnection connection,
    ChannelListItem channelListItem,
  ) async {
    if (!connection.isConnected) return;

    await _relayBuffer?.desync();

    final bufferFullName = channelListItem.fullName;
    final bufferName = channelListItem.name;
    final bufferPtr = channelListItem.bufferPointer;
    final buffer = RelayBuffer(
      relayConnection: connection,
      bufferPointer: bufferPtr,
      name: bufferName,
    );

    await buffer.sync();

    // close the drawer
    scaffoldState.closeDrawer();

    // switch buffer on remote weechat
    await connection.command('input core.weechat /buffer $bufferFullName');

    setState(() {
      _relayBuffer = buffer;
    });
  }

  Widget _showConnectionErrors(context, {String? reason}) {
    final l = AppLocalizations.of(context)!;

    if (reason == CONNECTION_CLOSED_REMOTE) {
      reason = l.errorConnectionClosedRemotely;
    } else if (reason == CONNECTION_CLOSED_OS) {
      reason = l.errorNotConnected;
    } else if (reason == CONNECTION_TIMEOUT) {
      reason = l.errorConnectionTimeout;
    } else if (reason == CERTIFICATE_VERIFY_FAILED) {
      reason = l.errorConnectionInvalidCertificate;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      child: Container(
        padding: const EdgeInsets.all(5),
        child: Text(reason ?? l.errorNotConnected),
      ),
    );
  }
}
