import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:weechat/pages/home.dart';
import 'package:weechat/pages/settings/config.dart';
import 'package:weechat/themes.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // lookup config path
  final appDir = await getApplicationDocumentsDirectory();
  final configPath = join(appDir.path, 'config.json');

  // create config
  final config = Config(path: configPath);

  // check if locale is part of supported locales
  Locale locale = Locale('en');
  for (final l in window.locales) {
    final lang = Locale(l.languageCode);
    if (AppLocalizations.supportedLocales.contains(lang)) {
      locale = lang;
      break;
    }
  }

  // set default locale to detected language code for consistent translations
  Intl.defaultLocale = locale.languageCode;

  // run application
  runApp(MyApp(
    config: config,
  ));
}

class MyApp extends StatelessWidget {
  final Config config;

  MyApp({required this.config});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: config),
        ],
        builder: (context, child) => _app(context, child),
      );

  Widget _app(BuildContext context, Widget? child) => MaterialApp(
        title: 'Weechat Mobile',

        // Theming
        theme: mainLightTheme,
        darkTheme: mainDarkTheme,

        // Localizations
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,

        // Pages
        home: HomePage(title: 'Flutter Demo Home Page'),
      );
}
