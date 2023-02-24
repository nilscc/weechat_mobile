import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:weechat/pages/settings/config.dart';

class UiSettings extends StatefulWidget {
  const UiSettings({super.key});
  
  @override
  State<UiSettings> createState() => _State();
}

class _State extends State<UiSettings> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final config = Config.of(context);

    return Column(
      children: [
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
      ],
    );
  }
}
