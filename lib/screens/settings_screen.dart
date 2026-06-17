import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echo_thread/screens/profile_screen.dart';
import 'package:echo_thread/screens/login_screen.dart';
import 'package:echo_thread/services/theme_service.dart';
import 'package:echo_thread/services/notification_service.dart';
import 'package:echo_thread/widgets/navigation_drawer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String _selectedLanguage = 'English';
  bool _emailNotifications = true;
  bool _smsNotifications = true;

  // Developer Notification Keys Setup
  final _brevoKeyController = TextEditingController();
  final _senderNameController = TextEditingController();
  final _senderEmailController = TextEditingController();
  final _smsSenderController = TextEditingController();
  final _twilioSidController = TextEditingController();
  final _twilioTokenController = TextEditingController();
  final _twilioFromController = TextEditingController();
  String _smsProvider = 'brevo';
  bool _isLoadingKeys = false;
  bool _isSavingKeys = false;

  @override
  void initState() {
    super.initState();
    _loadDeveloperKeys();
  }

  @override
  void dispose() {
    _brevoKeyController.dispose();
    _senderNameController.dispose();
    _senderEmailController.dispose();
    _smsSenderController.dispose();
    _twilioSidController.dispose();
    _twilioTokenController.dispose();
    _twilioFromController.dispose();
    super.dispose();
  }

  Future<void> _loadDeveloperKeys() async {
    setState(() => _isLoadingKeys = true);
    try {
      final doc = await _firestore.collection('config').doc('notifications').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _brevoKeyController.text = data['brevo_api_key'] ?? '';
        _senderNameController.text = data['email_sender_name'] ?? 'EchoThread Platform';
        _senderEmailController.text = data['email_sender_email'] ?? 'noreply@echothread.org';
        _smsSenderController.text = data['sms_sender'] ?? 'EchoThread';
        _twilioSidController.text = data['twilio_account_sid'] ?? '';
        _twilioTokenController.text = data['twilio_auth_token'] ?? '';
        _twilioFromController.text = data['twilio_from'] ?? '';
        _smsProvider = data['sms_provider'] ?? 'brevo';
      }
    } catch (e) {
      debugPrint('Error loading config keys: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingKeys = false);
      }
    }
  }

  Future<void> _saveDeveloperKeys() async {
    setState(() => _isSavingKeys = true);
    try {
      await _firestore.collection('config').doc('notifications').set({
        'brevo_api_key': _brevoKeyController.text.trim(),
        'email_sender_name': _senderNameController.text.trim(),
        'email_sender_email': _senderEmailController.text.trim(),
        'sms_sender': _smsSenderController.text.trim(),
        'twilio_account_sid': _twilioSidController.text.trim(),
        'twilio_auth_token': _twilioTokenController.text.trim(),
        'twilio_from': _twilioFromController.text.trim(),
        'sms_provider': _smsProvider,
      });
      NotificationService.clearCache(); // Force service to reload new config
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API Configuration Saved Successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save config: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingKeys = false);
      }
    }
  }

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
              title: const Text("Change Password"),
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
                  child: const Text("Cancel"),
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
                                  const SnackBar(
                                    content: Text("Password updated successfully!"),
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
                      : const Text("Update", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeveloperOptionsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Developer Credentials Editor",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Text(
                      "Setup your own API credentials to test Real notifications.",
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const Divider(height: 24),
                    const Text("Brevo (Sendinblue) Email & SMS Setup", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2E7D32))),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _brevoKeyController,
                      decoration: const InputDecoration(labelText: "Brevo API Key", hintText: "xkeysib-..."),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _senderNameController,
                            decoration: const InputDecoration(labelText: "Email Sender Name"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _senderEmailController,
                            decoration: const InputDecoration(labelText: "Email Sender Email"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _smsSenderController,
                      decoration: const InputDecoration(labelText: "SMS Sender Name", hintText: "Max 11 chars"),
                    ),
                    const Divider(height: 24),
                    const Text("Twilio SMS Setup (Optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1565C0))),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _twilioSidController,
                      decoration: const InputDecoration(labelText: "Twilio Account SID"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _twilioTokenController,
                      decoration: const InputDecoration(labelText: "Twilio Auth Token"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _twilioFromController,
                      decoration: const InputDecoration(labelText: "Twilio Phone Number (From)"),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _smsProvider,
                      decoration: const InputDecoration(labelText: "SMS Provider Mode"),
                      items: const [
                        DropdownMenuItem(value: 'brevo', child: Text('Brevo SMS')),
                        DropdownMenuItem(value: 'twilio', child: Text('Twilio SMS')),
                        DropdownMenuItem(value: 'simulated', child: Text('Simulated Fallback (Firestore Logs)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => _smsProvider = val);
                          setState(() => _smsProvider = val);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isSavingKeys
                            ? null
                            : () async {
                                setSheetState(() => _isSavingKeys = true);
                                await _saveDeveloperKeys();
                                setSheetState(() => _isSavingKeys = false);
                                if (context.mounted) Navigator.pop(context);
                              },
                        child: _isSavingKeys
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Save API Config", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      drawer: const AppNavigationDrawer(currentRoute: "settings"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "App Preferences",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 10),

            // 🎨 Theme Selector Card
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.palette_outlined),
                        SizedBox(width: 14),
                        Text("Theme Mode", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.language_outlined),
                        SizedBox(width: 14),
                        Text("Language Selection", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                      ],
                    ),
                    DropdownButton<String>(
                      value: _selectedLanguage,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'English', child: Text('English')),
                        DropdownMenuItem(value: 'Spanish', child: Text('Español')),
                        DropdownMenuItem(value: 'French', child: Text('Français')),
                        DropdownMenuItem(value: 'Hindi', child: Text('हिन्दी')),
                      ],
                      onChanged: (lang) {
                        if (lang != null) {
                          setState(() {
                            _selectedLanguage = lang;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Account & Privacy Settings",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 10),

            // Account settings item
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text("Edit Profile Credentials", style: TextStyle(fontWeight: FontWeight.w500)),
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
                title: const Text("Change Account Password", style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showChangePasswordDialog,
              ),
            ),
            const SizedBox(height: 8),

            // Notification preferences item
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.notifications_none_outlined),
                title: const Text("Notification Settings", style: TextStyle(fontWeight: FontWeight.w500)),
                children: [
                  SwitchListTile(
                    title: const Text("Email Alerts"),
                    subtitle: const Text("Receive login and registration notifications"),
                    value: _emailNotifications,
                    onChanged: (val) {
                      setState(() {
                        _emailNotifications = val;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text("SMS Alerts"),
                    subtitle: const Text("Receive direct updates on your cell phone"),
                    value: _smsNotifications,
                    onChanged: (val) {
                      setState(() {
                        _smsNotifications = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Privacy options card
            Card(
              child: ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text("Privacy Policies & Terms", style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.launch_outlined),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Privacy Settings"),
                      content: const Text(
                        "At EchoThread, we secure your information. All profiles, images, and user details are stored securely using Cloud Firebase Authentication and authorized Firestore security rules.",
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Developer Sandbox Configurations",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 10),

            // Developer API config card
            Card(
              child: ListTile(
                leading: const Icon(Icons.key_outlined, color: Colors.orange),
                title: const Text("Notification API Keys Setup", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Configure Brevo / Twilio API Details"),
                trailing: _isLoadingKeys
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.edit_note, color: Colors.orange),
                onTap: _showDeveloperOptionsSheet,
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
                label: const Text(
                  "Log Out from Account",
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
