import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  /// Load persisted language choice on startup
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString('language_preference') ?? 'en';
      _locale = Locale(savedLang);
      notifyListeners();
    } catch (e) {
      debugPrint('[LANGUAGE_SERVICE] Init failed: $e');
    }
  }

  /// Update language and save it to SharedPreferences
  Future<void> setLanguage(String languageCode) async {
    if (_locale.languageCode == languageCode) return;
    _locale = Locale(languageCode);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_preference', languageCode);
    } catch (e) {
      debugPrint('[LANGUAGE_SERVICE] Save preference failed: $e');
    }
  }

  /// Readable name helper
  String get languageName {
    switch (_locale.languageCode) {
      case 'kn':
        return 'ಕನ್ನಡ (Kannada)';
      case 'hi':
        return 'हिन्दी (Hindi)';
      case 'en':
      default:
        return 'English';
    }
  }
}
