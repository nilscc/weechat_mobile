import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:weechat/pages/settings/config.dart';

class ConnectionSettings extends StatefulWidget {
  const ConnectionSettings({super.key});
  
  @override
  State<ConnectionSettings> createState() => _State();
}

class _State extends State<ConnectionSettings> {
  @override
  Widget build(BuildContext context) {
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

    return Column(
      children: [
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
            onChanged: (newValue) => setState(() {
              config.verifyCert = newValue;
            }),
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
      ],
    );
  }
}
