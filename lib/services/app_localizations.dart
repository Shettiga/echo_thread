import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title': 'EchoThread',
      'login': 'Login',
      'register': 'Register',
      'email': 'Email Address',
      'password': 'Password',
      'phone': 'Phone Number',
      'name': 'Name',
      'role': 'Role',
      'dashboard': 'Dashboard',
      'profile': 'My Profile',
      'settings': 'Settings',
      'help': 'Help & Support',
      'about': 'About EchoThread',
      'logout': 'Logout',
      'welcome': 'Welcome Back',
      'theme_mode': 'Theme Mode',
      'selected_theme': 'Selected Theme',
      'language_selection': 'Language Selection',
      'selected_language': 'Selected Language',
      'donations': 'Donations',
      'volunteers': 'Volunteers',
      'users': 'Users',
      'status': 'Status',
      'active': 'Active',
      'inactive': 'Inactive',
      'accept_task': 'Accept Task',
      'mark_pickup': 'Mark Pickup Completed',
      'mark_delivered': 'Mark Delivered',
      'category': 'Category',
      'quantity': 'Quantity',
      'pickup_address': 'Pickup Address',
      'date': 'Date',
      'actions': 'Actions',
      'forgot_password': 'Forgot Password?',
      'dont_have_account': 'Don\'t have an account?',
      'already_have_account': 'Already have an account?',
      'enter_details': 'Enter your credentials to continue',
      'sign_in': 'Sign In',
      'sign_up': 'Sign Up',
      'about_mission': 'Our Mission',
      'about_project': 'Our Project',
      'about_dev': 'Developer Information',
      'about_contact': 'Contact Information',
      'home': 'Home',
    },
    'kn': {
      'title': 'ಎಕೋಥ್ರೆಡ್',
      'login': 'ಲಾಗಿನ್',
      'register': 'ನೋಂದಣಿ',
      'email': 'ಇಮೇಲ್ ವಿಳಾಸ',
      'password': 'ಗುಪ್ತಪದ',
      'phone': 'ದೂರವಾಣಿ ಸಂಖ್ಯೆ',
      'name': 'ಹೆಸರು',
      'role': 'ಪಾತ್ರ',
      'dashboard': 'ಡ್ಯಾಶ್‌ಬೋರ್ಡ್',
      'profile': 'ನನ್ನ ಪ್ರೊಫೈಲ್',
      'settings': 'ಸಂಯೋಜನೆಗಳು',
      'help': 'ಸಹಾಯ ಮತ್ತು ಬೆಂಬಲ',
      'about': 'ಎಕೋಥ್ರೆಡ್ ಬಗ್ಗೆ',
      'logout': 'ಲಾಗ್ ಔಟ್',
      'welcome': 'ಸ್ವಾಗತ',
      'theme_mode': 'ಥೀಮ್ ಮೋಡ್',
      'selected_theme': 'ಆಯ್ಕೆಮಾಡಿದ ಥೀಮ್',
      'language_selection': 'ಭಾಷೆ ಆಯ್ಕೆ',
      'selected_language': 'ಆಯ್ಕೆಮಾಡಿದ ಭಾಷೆ',
      'donations': 'ದೇಣಿಗೆಗಳು',
      'volunteers': 'ಸ್ವಯಂಸೇವಕರು',
      'users': 'ಬಳಕೆದಾರರು',
      'status': 'ಸ್ಥಿತಿ',
      'active': 'ಸಕ್ರಿಯ',
      'inactive': 'ನಿಷ್ಕ್ರಿಯ',
      'accept_task': 'ಕಾರ್ಯ ಸ್ವೀಕರಿಸಿ',
      'mark_pickup': 'ಪಿಕಪ್ ಪೂರ್ಣಗೊಂಡಿದೆ ಎಂದು ಗುರುತಿಸಿ',
      'mark_delivered': 'ತಲುಪಿಸಲಾಗಿದೆ ಎಂದು ಗುರುತಿಸಿ',
      'category': 'ವರ್ಗ',
      'quantity': 'ಪ್ರಮಾಣ',
      'pickup_address': 'ಪಿಕಪ್ ವಿಳಾಸ',
      'date': 'ದಿನಾಂಕ',
      'actions': 'ಕ್ರಮಗಳು',
      'forgot_password': 'ಪಾಸ್ವರ್ಡ್ ಮರೆತಿದ್ದೀರಾ?',
      'dont_have_account': 'ಖಾತೆ ಹೊಂದಿಲ್ಲವೇ?',
      'already_have_account': 'ಈಗಾಗಲೇ ಖಾತೆ ಹೊಂದಿದ್ದೀರಾ?',
      'enter_details': 'ಮುಂದುವರೆಯಲು ನಿಮ್ಮ ರುಜುವಾತುಗಳನ್ನು ನಮೂದಿಸಿ',
      'sign_in': 'ಸೈನ್ ಇನ್',
      'sign_up': 'ಸೈನ್ ಅಪ್',
      'about_mission': 'ನಮ್ಮ ಧ್ಯೇಯ',
      'about_project': 'ನಮ್ಮ ಯೋಜನೆ',
      'about_dev': 'ಡೆವಲಪರ್ ಮಾಹಿತಿ',
      'about_contact': 'ಸಂಪರ್ಕ ಮಾಹಿತಿ',
      'home': 'ಮುಖಪುಟ',
    },
    'hi': {
      'title': 'इकोथ्रेड',
      'login': 'लॉगिन',
      'register': 'पंजीकरण',
      'email': 'ईमेल पता',
      'password': 'पासवर्ड',
      'phone': 'फ़ोन नंबर',
      'name': 'नाम',
      'role': 'भूमिका',
      'dashboard': 'डैशबोर्ड',
      'profile': 'मेरी प्रोफाइल',
      'settings': 'सेटिंग्स',
      'help': 'सहायता और सहायता',
      'about': 'इकोथ्रेड के बारे में',
      'logout': 'लॉग आउट',
      'welcome': 'स्वागत हे',
      'theme_mode': 'थीम मोड',
      'selected_theme': 'चयनित थीम',
      'language_selection': 'भाषा चयन',
      'selected_language': 'चयनित भाषा',
      'donations': 'दान',
      'volunteers': 'स्वयंसेवक',
      'users': 'उपयोगकर्ता',
      'status': 'स्थिति',
      'active': 'सक्रिय',
      'inactive': 'निष्क्रिय',
      'accept_task': 'कार्य स्वीकार करें',
      'mark_pickup': 'पिकअप पूर्ण चिह्नित करें',
      'mark_delivered': 'वितरित चिह्नित करें',
      'category': 'श्रेणी',
      'quantity': 'मात्रा',
      'pickup_address': 'पिकअप पता',
      'date': 'दिनांक',
      'actions': 'कार्रवाई',
      'forgot_password': 'पासवर्ड भूल गए?',
      'dont_have_account': 'खाता नहीं है?',
      'already_have_account': 'पहले से ही एक खाता है?',
      'enter_details': 'जारी रखने के लिए अपने क्रेडेंशियल दर्ज करें',
      'sign_in': 'साइन इन',
      'sign_up': 'साइन अप',
      'about_mission': 'हमारा लक्ष्य',
      'about_project': 'हमारी परियोजना',
      'about_dev': 'डेवलपर की जानकारी',
      'about_contact': 'संपर्क जानकारी',
      'home': 'मुख्य पृष्ठ',
    }
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'kn', 'hi'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}

extension LocalizationExtension on BuildContext {
  String translate(String key) => AppLocalizations.of(this)?.translate(key) ?? key;
}
