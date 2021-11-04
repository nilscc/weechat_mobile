import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:weechat/pages/settings/config.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();

  static MaterialPageRoute route({Key? key}) =>
      MaterialPageRoute(builder: (context) => SettingsPage(key: key));
}

class _SettingsState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settingsTitle),
      ),
      body: ListView(
        children: [
          ..._connectionSettings(context),
        ],
      ),
    );
  }

  List<Widget> _connectionSettings(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final config = Config.of(context);

    final hostNameController = TextEditingController(
      text: config.hostName ?? '',
    );
    final portNumberController = TextEditingController(
      text: config.portNumber?.toString() ?? '',
    );
    final relayPasswordController = TextEditingController(
      text: config.relayPassword?.toString() ?? '',
    );

    return [
      Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: ListTile(
          title: Text(loc.settingsConnectionTitle),
          subtitle: Text(loc.settingsConnectionSubtitle),
        ),
      ),
      Container(
        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
        child: TextField(
          controller: hostNameController,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            icon: Icon(Feather.server),
            labelText: loc.settingsConnectionHostname,
          ),
          onChanged: (value) => config.hostName = value,
        ),
      ),
      Container(
        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
        child: TextField(
          controller: portNumberController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: loc.settingsConnectionPort,
            icon: Icon(Feather.hash),
          ),
          onChanged: (value) => config.portNumber = int.tryParse(value),
        ),
      ),
      Container(
        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
        child: TextField(
          controller: relayPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: loc.settingsConnectionRelayPassword,
            icon: Icon(Feather.lock),
          ),
          onChanged: (value) => config.relayPassword = value,
        ),
      ),
    ];
  }
}
