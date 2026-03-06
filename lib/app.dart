import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/camera/presentation/pages/home_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Light Meter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}