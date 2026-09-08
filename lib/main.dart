import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/settings_controller.dart';
import 'screens/home_page.dart';
import 'screens/verification_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  final settings = SettingsController();
  await settings.init();

  runApp(MyApp(settings: settings));
}

class MyApp extends StatelessWidget {
  final SettingsController settings;

  const MyApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'My Study Archive',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A73E8),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A73E8),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: settings.flutterThemeMode,
          home: settings.hasAccess
              ? HomePage(settings: settings)
              : VerificationPage(settings: settings),
        );
      },
    );
  }
}