import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:weechat/pages/home.dart';
import 'package:weechat/pages/log/event_logger.dart';
import 'package:weechat/pages/settings/config.dart';
import 'package:weechat/relay/connection.dart';
import 'package:weechat/relay/connection/status.dart';
import 'package:weechat/themes.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
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

  // connection status is kept globally
  final cs = RelayConnectionStatus();
  final con = RelayConnection(connectionStatus: cs);
  final log = EventLogger();

  // run application with exception handling
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // lookup config path
    final appDir = await getApplicationDocumentsDirectory();
    final configPath = join(appDir.path, 'config.json');

    // create config
    final config = Config(path: configPath);

    runApp(MyApp(
      config: config,
      connection: con,
      eventLogger: log,
    ));
  }, (error, stack) {
    log.error('runZonedGuarded: $error');
    if (error is SocketException) {
      con.close(reason: CONNECTION_CLOSED);
    } else if (error is TimeoutException) {
      con.close(reason: CONNECTION_TIMEOUT);
    } else
      throw error;
  });
}

class MyApp extends StatelessWidget {
  final Config config;
  final RelayConnection connection;
  final EventLogger eventLogger;

  MyApp({
    required this.config,
    required this.connection,
    required this.eventLogger,
  }) {
    // link up connection status with event logger
    this.connection.connectionStatus.eventLogger = eventLogger;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          Provider<Config>.value(value: config),
          ChangeNotifierProvider.value(value: connection.connectionStatus),
          Provider<RelayConnection>.value(value: connection),
          ChangeNotifierProvider.value(value: eventLogger),
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
        home: HomePage(),
      );
}
