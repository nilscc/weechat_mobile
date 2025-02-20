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
import 'package:weechat/l10n/app_localizations.dart';

void main() async {
  // get platform dispatcher. this needs to be done through the singleton as described on
  // https://api.flutter.dev/flutter/dart-ui/PlatformDispatcher/instance.html
  final dispatcher = PlatformDispatcher.instance;
  // check if locale is part of supported locales
  Locale locale = const Locale('en');
  for (final l in dispatcher.locales) {
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
  }, (error, stack) async {
    log.error('runZonedGuarded: $error');

    String reason;
    if (error is SocketException) {
      if (error.osError?.errorCode == 9) {
        reason = CONNECTION_CLOSED_OS;
      } else {
        reason = CONNECTION_CLOSED_REMOTE;
      }
    } else if (error is TimeoutException) {
      reason = CONNECTION_TIMEOUT;
    } else if (error is HandshakeException &&
        (error.osError?.message.contains("CERTIFICATE_VERIFY_FAILED") ??
            false)) {
      reason = CERTIFICATE_VERIFY_FAILED;
    } else {
      throw error;
    }

    await con.close(reason: reason);
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
    super.key,
  }) {
    // link up connection status with event logger
    connection.connectionStatus.eventLogger = eventLogger;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: config),
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
        home: const HomePage(),
      );
}
