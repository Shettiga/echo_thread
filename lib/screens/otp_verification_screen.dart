import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:echo_thread/services/notification_service.dart';
import 'package:echo_thread/screens/reset_password_screen.dart';
import 'package:echo_thread/services/theme_service.dart';
import 'package:echo_thread/services/app_localizations.dart';

import 'donor_dashboard.dart';
import 'ngo_dashboard.dart';
import 'volunteer_dashboard.dart';
import 'admin_dashboard.dart';

enum OtpPurpose { forgotPassword, register, login }

class OtpVerificationScreen extends StatefulWidget {
  final String? email;
  final String? phone;
  final String userName;
  final OtpPurpose purpose;

  // Additional data for registration
  final String? regPassword;
  final String? regRole;

  const OtpVerificationScreen({
    super.key,
    this.email,
    this.phone,
    required this.userName,
    required this.purpose,
    this.regPassword,
    this.regRole,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  Timer? _timer;
  int _secondsRemaining = 300; // 5 minutes expiry
  int _secondsToResend = 60;   // Resend available after 60 seconds
  bool _isResendAvailable = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 300;
      _secondsToResend = 60;
      _isResendAvailable = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _timer?.cancel();
          }

          if (_secondsToResend > 0) {
            _secondsToResend--;
          } else {
            _isResendAvailable = true;
          }
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);
    try {
      if (widget.purpose == OtpPurpose.forgotPassword) {
        // Generate new Email OTP
        final random = Random();
        final newOtp = (100000 + random.nextInt(900000)).toString();
        final expiresAt = DateTime.now().add(const Duration(minutes: 5));

        await FirebaseFirestore.instance.collection('password_resets').doc(widget.email).set({
          'email': widget.email,
          'otp': newOtp,
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(expiresAt),
        });

        // Backend trigger onPasswordResetCreated sends the email automatically.
        // We also fall back to NotificationService mock if SMTP is missing
        await NotificationService.sendEmail(
          email: widget.email!,
          name: widget.userName,
          activity: "Resend Forgot Password (OTP Code: $newOtp)",
          dateTime: DateTime.now(),
        );
      } else {
        // SMS OTP resend call using our secure backend Cloud Function
        final projectId = Firebase.app().options.projectId;
        final functionUrl = 'https://us-central1-$projectId.cloudfunctions.net/sendSMSOTP';
        
        final response = await http.post(
          Uri.parse(functionUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'data': {
              'phone': widget.phone,
            }
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode != 200) {
          throw Exception('Failed to send OTP via Cloud Function: ${response.statusCode}');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("A new OTP verification code has been sent!"),
            backgroundColor: Colors.green,
          ),
        );
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error resending OTP: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    final enteredOtp = _otpController.text.trim();

    if (enteredOtp.isEmpty || enteredOtp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid 6-digit OTP code.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.purpose == OtpPurpose.forgotPassword) {
        // 1. Fetch OTP details from Firestore (Email flow)
        final doc = await FirebaseFirestore.instance
            .collection('password_resets')
            .doc(widget.email)
            .get();

        if (!doc.exists) {
          _showErrorDialog("OTP Invalid", "We could not find an active OTP request for this email. Please request a new one.");
          return;
        }

        final data = doc.data()!;
        final dbOtp = data['otp'] as String;
        final expiresAt = (data['expiresAt'] as Timestamp).toDate();

        if (DateTime.now().isAfter(expiresAt)) {
          _showErrorDialog("OTP Expired", "This OTP code has expired. Please tap 'Resend OTP' to get a new one.");
          return;
        }

        if (enteredOtp != dbOtp) {
          _showErrorDialog("Invalid Code", "The OTP code you entered is incorrect. Please try again.");
          return;
        }

        // Email OTP Succeeded: Go to reset screen
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("OTP verified successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(email: widget.email!, otp: enteredOtp),
            ),
          );
        }
      } else {
        // SMS flow - call backend Cloud Function verifySMSOTP
        final projectId = Firebase.app().options.projectId;
        final functionUrl = 'https://us-central1-$projectId.cloudfunctions.net/verifySMSOTP';

        final response = await http.post(
          Uri.parse(functionUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'data': {
              'phone': widget.phone,
              'otp': enteredOtp,
            }
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode != 200) {
          _showErrorDialog("Verification Failed", "Verify API returned status ${response.statusCode}");
          return;
        }

        final responseData = jsonDecode(response.body);
        if (responseData['result']?['success'] != true) {
          final err = responseData['result']?['error'] ?? 'Incorrect OTP code entered.';
          _showErrorDialog("Invalid OTP", err);
          return;
        }

        // SMS OTP Succeeded!
        if (widget.purpose == OtpPurpose.register) {
          // Complete registration by creating user credentials now
          final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: widget.email!,
            password: widget.regPassword!,
          );

          final uid = credential.user!.uid;
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'name': widget.userName,
            'email': widget.email,
            'phone': widget.phone,
            'role': widget.regRole,
            'profileImage': '',
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Registration complete, auto log-in is handled by auth state listeners.
          // Sign in using the created credentials to navigate to dashboard
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Account created successfully! Welcome!"), backgroundColor: Colors.green),
            );
            _navigateToDashboard(widget.regRole ?? 'Donor');
          }
        } else if (widget.purpose == OtpPurpose.login) {
          // Complete login: they are already logged in via Firebase Auth,
          // so just proceed to their dashboard
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
            final role = userDoc.data()?['role'] ?? 'Donor';
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Login verified! Welcome back, ${widget.userName}"), backgroundColor: Colors.green),
              );
              _navigateToDashboard(role);
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verification error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToDashboard(String role) {
    final String r = role.toLowerCase();
    Widget targetDashboard;
    if (r == 'admin') {
      targetDashboard = const AdminDashboard();
    } else if (r == 'ngo') {
      targetDashboard = const NGODashboard();
    } else if (r == 'volunteer') {
      targetDashboard = const VolunteerDashboard();
    } else {
      targetDashboard = const DonorDashboard();
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => targetDashboard),
      (route) => false,
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService().isDark(context);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("OTP Verification"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // If they cancel out of login verification, sign them out so they don't bypass auth
            if (widget.purpose == OtpPurpose.login) {
              FirebaseAuth.instance.signOut();
            }
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 4,
              color: cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.security_outlined,
                        size: 48,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Enter Verification Code",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "We've sent a 6-digit security code to ${widget.phone ?? widget.email}. Please enter it below.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8, color: isDark ? Colors.white : Colors.black87),
                      decoration: const InputDecoration(
                        counterText: "",
                        hintText: "000000",
                        hintStyle: TextStyle(color: Colors.grey, letterSpacing: 8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _secondsRemaining > 0
                                  ? "Expires in: ${_formatTime(_secondsRemaining)}"
                                  : "Code expired",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _secondsRemaining > 0 ? (isDark ? Colors.white70 : Colors.black54) : Colors.red,
                              ),
                            ),
                            if (!_isResendAvailable)
                              Text(
                                "Resend in: $_secondsToResend s",
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                          ],
                        ),
                        TextButton(
                          onPressed: _isResendAvailable && !_isLoading ? _resendOtp : null,
                          child: Text(
                            "Resend OTP",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _isResendAvailable ? primaryColor : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isLoading || _secondsRemaining == 0 ? null : _verifyOtp,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "Verify OTP Code",
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
