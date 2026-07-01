import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echo_thread/screens/login_screen.dart';
import 'package:echo_thread/config.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.otp,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final passwordText = _passwordController.text.trim();
    final confirmText = _confirmController.text.trim();

    if (passwordText.isEmpty || confirmText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all password fields.")),
      );
      return;
    }

    if (passwordText.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters.")),
      );
      return;
    }

    if (passwordText != confirmText) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final functionUrl = '${AppConfig.backendUrl}/api/password-reset';

      debugPrint('[RESET_PASSWORD] Triggering Express API request at: $functionUrl');
      
      bool functionSucceeded = false;
      String errorMessage = '';

      try {
        final response = await http.post(
          Uri.parse(functionUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': widget.email,
            'otp': widget.otp,
            'newPassword': passwordText,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          if (responseData['result']?['success'] == true) {
            functionSucceeded = true;
          } else {
            errorMessage = responseData['result']?['error'] ?? 'Function returned an error status.';
          }
        } else {
          errorMessage = 'HTTP ${response.statusCode}';
        }
      } catch (e) {
        errorMessage = e.toString();
        debugPrint('[RESET_PASSWORD] HTTP request error: $e');
      }

      if (functionSucceeded) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text("Success 🎉"),
              content: const Text("Your password has been successfully updated in Firebase Authentication. You can now log in."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text("Go to Login"),
                ),
              ],
            ),
          );
        }
      } else {
        // Fallback simulation behavior
        debugPrint('[RESET_PASSWORD] Could not connect to real Cloud Function: $errorMessage. Initiating fallback simulation...');

        // Register request in Firestore request logs
        await FirebaseFirestore.instance.collection('password_reset_requests').add({
          'email': widget.email,
          'otp': widget.otp,
          'status': 'Simulated Succeeded (Cloud Function Pending)',
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Clean up the OTP doc in Firestore
        await FirebaseFirestore.instance.collection('password_resets').doc(widget.email).delete();

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blueAccent),
                  SizedBox(width: 8),
                  Text("Password Reset Simulated", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Text(
                "Your OTP verification was successful. For security, Firebase client-side SDKs cannot directly write to Authentication credentials.\n\n"
                "We have registered the reset request in Firestore and deleted the OTP. Please deploy the provided Cloud Function to enable automatic updates.\n\n"
                "Error Detail: $errorMessage"
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text("Continue to Login"),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Reset Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Password"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.vpn_key_outlined,
                        size: 48,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Create New Password",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Please choose a strong, secure new password that you don't use on other applications.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "New Password",
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Confirm New Password",
                        prefixIcon: Icon(Icons.lock_clock_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isLoading ? null : _resetPassword,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "Reset Password",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
