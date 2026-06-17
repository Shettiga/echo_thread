import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';   // ✅ ADD THIS
import 'screens/splash_screen.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();   // ✅ REQUIRED
  try {
    debugPrint("[FIREBASE_INIT] Starting Firebase initialization...");
    await Firebase.initializeApp();              // ✅ INITIALIZE FIREBASE
    debugPrint("[FIREBASE_INIT] Firebase initialization succeeded.");
  } catch (e) {
    debugPrint("[FIREBASE_INIT_ERROR] Firebase initialization failed: $e");
  }
  
  final themeService = ThemeService();
  await themeService.init();
  
  runApp(const EcchoThreadApp());
}

class EcchoThreadApp extends StatelessWidget {
  const EcchoThreadApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();

    return ListenableBuilder(
      listenable: themeService,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Eccho Thread',
          themeMode: themeService.themeMode,
          theme: themeService.lightTheme,
          darkTheme: themeService.darkTheme,
          home: const SplashScreen(),   // ✅ KEEP YOUR EXISTING FLOW
        );
      },
    );
  }
}