import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/splash_screen.dart';
import 'services/theme_service.dart';
import 'services/language_service.dart';
import 'services/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();   // REQUIRED
  try {
    debugPrint("[FIREBASE_INIT] Starting Firebase initialization...");
    await Firebase.initializeApp();              // INITIALIZE FIREBASE
    debugPrint("[FIREBASE_INIT] Firebase initialization succeeded.");
  } catch (e) {
    debugPrint("[FIREBASE_INIT_ERROR] Firebase initialization failed: $e");
  }
  
  final themeService = ThemeService();
  await themeService.init();

  final languageService = LanguageService();
  await languageService.init();
  
  runApp(const EcchoThreadApp());
}

class EcchoThreadApp extends StatelessWidget {
  const EcchoThreadApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();
    final languageService = LanguageService();

    return ListenableBuilder(
      listenable: Listenable.merge([themeService, languageService]),
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Echo Thread',
          locale: languageService.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('kn'),
            Locale('hi'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          themeMode: themeService.themeMode,
          theme: themeService.lightTheme,
          darkTheme: themeService.darkTheme,
          home: const SplashScreen(),   // ✅ KEEP YOUR EXISTING FLOW
        );
      },
    );
  }
}