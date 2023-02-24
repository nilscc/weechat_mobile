import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:weechat/pages/settings/config.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SshUploadSettings extends StatefulWidget {
  const SshUploadSettings({super.key});

  @override
  State<SshUploadSettings> createState() => _SshUploadSettingsState();
}

class _SshUploadSettingsState extends State<SshUploadSettings> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final config = Config.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: const ListTile(
            title: Text('SSH'),
            subtitle: Text('Upload files to SSH'),
          ),
        ),
      ],
    );
  }
}
