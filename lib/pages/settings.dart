import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:weechat/pages/settings/config.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsState();

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
          ..._uiSettings(context),
          const Padding(
            padding: EdgeInsets.only(bottom: 100),
          ),
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
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: ListTile(
          title: Text(loc.settingsConnectionTitle),
          subtitle: Text(loc.settingsConnectionSubtitle),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
        child: TextField(
          controller: hostNameController,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            icon: const Icon(Feather.server),
            labelText: loc.settingsConnectionHostname,
          ),
          onChanged: (value) => config.hostName = value,
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
        child: TextField(
          controller: portNumberController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: loc.settingsConnectionPort,
            icon: const Icon(Feather.hash),
          ),
          onChanged: (value) => config.portNumber = int.tryParse(value),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
        child: TextField(
          controller: relayPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: loc.settingsConnectionRelayPassword,
            icon: const Icon(Feather.lock),
          ),
          onChanged: (value) => config.relayPassword = value,
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
        child: CheckboxListTile(
          value: config.verifyCert ?? true,
          onChanged: (newValue) {
            setState(() {
              config.verifyCert = newValue;
            });
          },
          title: Text(loc.settingsConnectionVerifyCert),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
        child: CheckboxListTile(
          title: Text(loc.settingsConnectAutomatically),
          value: config.autoconnect,
          onChanged: (newValue) => setState(() {
            config.autoconnect = newValue ?? true;
          }),
        ),
      )
    ];
  }

  List<Widget> _uiSettings(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final config = Config.of(context);

    return [
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: ListTile(
          title: Text(loc.settingsUiTitle),
          subtitle: Text(loc.settingsUiSubtitle),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
        child: CheckboxListTile(
          value: config.uiShowCompletion ?? true,
          onChanged: (newValue) {
            setState(() {
              config.uiShowCompletion = newValue;
            });
          },
          title: Text(loc.settingsUiShowCompletion),
          secondary: const Icon(Icons.keyboard_tab),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
        child: CheckboxListTile(
          value: config.uiShowSend ?? false,
          onChanged: (newValue) {
            setState(() {
              config.uiShowSend = newValue;
            });
          },
          title: Text(loc.settingsUiShowSend),
          secondary: const Icon(Feather.arrow_up),
        ),
      ),
      ..._fontSettings(context),
    ];
  }

  List<Widget> _fontSettings(BuildContext context,
      {int minFontSize = 8, int maxFontSize = 32}) {
    final loc = AppLocalizations.of(context)!;
    final config = Config.of(context);

    return [
      Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
        child: ListTile(
          title: Row(
            children: [
              Text(loc.settingsFontSize),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Slider(
                    onChanged: (double value) {
                      setState(() {
                        config.fontSize = value.round();
                      });
                    },
                    value: max(
                            minFontSize,
                            min((config.fontSize ?? Config.defaultFontSize),
                                maxFontSize))
                        .toDouble(),
                    min: minFontSize.toDouble(),
                    max: maxFontSize.toDouble(),
                  ),
                ),
              ),
              Text("${config.fontSize ?? Config.defaultFontSize} pt")
            ],
          ),
        ),
      ),
    ];
  }
}
