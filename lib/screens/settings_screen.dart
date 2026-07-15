import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echo_thread/screens/profile_screen.dart';
import 'package:echo_thread/screens/login_screen.dart';
import 'package:echo_thread/services/theme_service.dart';
import 'package:echo_thread/widgets/navigation_drawer.dart';
import 'package:echo_thread/services/language_service.dart';
import 'package:echo_thread/services/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = FirebaseAuth.instance;
  bool _emailNotifications = true;

  void _showChangePasswordDialog() {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isChanging = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(context.translate('change_password')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "New Password",
                      hintText: "At least 6 characters",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Confirm New Password",
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isChanging ? null : () => Navigator.pop(context),
                  child: Text(context.translate('cancel')),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                  onPressed: isChanging
                      ? null
                      : () async {
                          final password = passwordController.text.trim();
                          final confirm = confirmPasswordController.text.trim();

                          if (password.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Password must be at least 6 characters.")),
                            );
                            return;
                          }

                          if (password != confirm) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Passwords do not match.")),
                            );
                            return;
                          }

                          setDialogState(() => isChanging = true);
                          try {
                            final user = _auth.currentUser;
                            if (user != null) {
                              await user.updatePassword(password);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(context.translate('password_updated')),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Error: $e"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            setDialogState(() => isChanging = false);
                          }
                        },
                  child: isChanging
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                        )
                      : Text(context.translate('update'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();
    final languageService = LanguageService();

    return ListenableBuilder(
      listenable: Listenable.merge([themeService, languageService]),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          appBar: AppBar(
            title: Text(context.translate('settings')),
          ),
          drawer: const AppNavigationDrawer(currentRoute: "settings"),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.translate('settings'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 10),

                // 🎨 Theme Selector Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.palette_outlined),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(context.translate('theme_mode'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                const SizedBox(height: 4),
                                Text(
                                  "${context.translate('selected_theme')}:\n${themeService.themeMode.name[0].toUpperCase()}${themeService.themeMode.name.substring(1)}",
                                  style: const TextStyle(color: Colors.grey, fontSize: 12.5, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        DropdownButton<ThemeMode>(
                          value: themeService.themeMode,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                            DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                            DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                          ],
                          onChanged: (mode) {
                            if (mode != null) {
                              themeService.setThemeMode(mode);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // 🌐 Language Selection Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.language_outlined),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(context.translate('language_selection'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                const SizedBox(height: 4),
                                Text(
                                  "${context.translate('selected_language')}:\n${languageService.languageName}",
                                  style: const TextStyle(color: Colors.grey, fontSize: 12.5, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        DropdownButton<String>(
                          value: languageService.locale.languageCode,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 'en', child: Text('English')),
                            DropdownMenuItem(value: 'kn', child: Text('ಕನ್ನಡ')),
                            DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
                          ],
                          onChanged: (lang) {
                            if (lang != null) {
                              languageService.setLanguage(lang);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  context.translate('theme_customizations'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 10),

                // Account settings item
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(context.translate('edit_profile'), style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // Change password item
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.lock_open_outlined),
                    title: Text(context.translate('change_account_password'), style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showChangePasswordDialog,
                  ),
                ),
                const SizedBox(height: 8),

                // Notification preferences item
                Card(
                  child: SwitchListTile(
                    secondary: const Icon(Icons.notifications_none_outlined),
                    title: Text(context.translate('email_alerts')),
                    subtitle: const Text("Receive login and registration notifications"),
                    value: _emailNotifications,
                    onChanged: (val) {
                      setState(() {
                        _emailNotifications = val;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // Privacy options card
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: Text(context.translate('privacy_policy'), style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.launch_outlined),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(context.translate('privacy_policy')),
                          content: const Text(
                            "At EchoThread, we secure your information. All profiles, images, and user details are stored securely using Cloud Firebase Authentication and authorized Firestore security rules.",
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: Text(context.translate('close'))),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Red logout button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: Text(
                      context.translate('logout'),
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
