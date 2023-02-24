import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:weechat/pages/settings/connection_settings.dart';
import 'package:weechat/pages/settings/ssh_upload_settings.dart';
import 'package:weechat/pages/settings/ui_settings.dart';

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
        children: const [
          ConnectionSettings(),
          UiSettings(),
          SshUploadSettings(),
        ],
      ),
    );
  }
}
