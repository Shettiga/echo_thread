import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';   // ✅ ADD THIS
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();   // ✅ REQUIRED
  await Firebase.initializeApp();              // ✅ INITIALIZE FIREBASE
  runApp(const EcchoThreadApp());
}

class EcchoThreadApp extends StatelessWidget {
  const EcchoThreadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Eccho Thread',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const SplashScreen(),   // ✅ KEEP YOUR EXISTING FLOW
    );
  }
}