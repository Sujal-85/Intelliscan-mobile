import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'core/theme/design_system.dart';
import 'screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().initialize();
  await ThemeService().init();
  runApp(const IntelliScanApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class IntelliScanApp extends StatelessWidget {
  const IntelliScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'IntelliScan',
          debugShowCheckedModeBanner: false,
          theme: DesignSystem.lightTheme,
          darkTheme: DesignSystem.darkTheme,
          themeMode: ThemeService().isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          home: const SplashScreen(),
        );
      },
    );
  }
}
