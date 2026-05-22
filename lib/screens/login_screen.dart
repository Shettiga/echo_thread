import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'register_screen.dart';
import 'donor_dashboard.dart';
import 'ngo_dashboard.dart';
import 'volunteer_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
  with TickerProviderStateMixin {
  bool obscurePassword = true;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  late final AnimationController _controller;
  late final Animation<double> _cardFadeAnimation;
  late final Animation<double> _cardScaleAnimation;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _logoRotateAnimation;
  late final Animation<double> _fieldsFadeAnimation;
  late final AnimationController _bgController;
  late final Animation<double> _bgAnim1;
  late final Animation<double> _bgAnim2;
  late final Animation<double> _bgAnim3;
  late final AnimationController _shakeController;

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _emailFocused = false;
  bool _passwordFocused = false;
  bool _isLoading = false;

  // 🔐 LOGIN FUNCTION
  Future<void> loginUser() async {
    try {
      UserCredential userCred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String uid = userCred.user!.uid;

      // 🔥 FETCH USER ROLE
      final userData = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (!userData.exists) {
        throw Exception("User profile not found.");
      }

      final data = userData.data();
      final role = data?['role'];

      if (!mounted) return;

      // ✅ SUCCESS MESSAGE
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login Successful 🎉"),
          backgroundColor: Colors.green,
        ),
      );

      // 🔀 ROLE BASED NAVIGATION
      if (role == "Donor") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const DonorDashboard(),
          ),
        );
      } else if (role == "NGO") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const NGODashboard(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const VolunteerDashboard(),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    _cardFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _cardScaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _logoRotateAnimation = Tween<double>(begin: -0.06, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.12, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _fieldsFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 1.0, curve: Curves.easeIn),
    );

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat(reverse: true);

    _bgAnim1 = Tween<double>(begin: -36.0, end: 36.0).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeInOut),
    );

    _bgAnim2 = Tween<double>(begin: -24.0, end: 24.0).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeInOutCubic),
    );

    _bgAnim3 = Tween<double>(begin: -48.0, end: 48.0).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeInOutQuint),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _emailFocus.addListener(() {
      setState(() {
        _emailFocused = _emailFocus.hasFocus;
      });
    });
    _passwordFocus.addListener(() {
      setState(() {
        _passwordFocused = _passwordFocus.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _bgController.dispose();
    _shakeController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // base gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF2E7D32),
                  Color(0xFF66BB6A),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // animated decorative blobs
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    left: -60 + _bgAnim1.value,
                    top: -40 + (_bgAnim2.value / 2),
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.06),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -80 - _bgAnim2.value,
                    top: 120 + (_bgAnim3.value / 3),
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.05),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 20 + _bgAnim3.value,
                    bottom: -60 - (_bgAnim1.value / 2),
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(0xFF8EE08E).withOpacity(0.12),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // main content
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: FadeTransition(
                  opacity: _cardFadeAnimation,
                  child: ScaleTransition(
                    scale: _cardScaleAnimation,
                    child: Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(25),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RotationTransition(
                              turns: _logoRotateAnimation,
                              child: ScaleTransition(
                                scale: _logoScaleAnimation,
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  height: 90,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              "Welcome Back!",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              "Login to continue",
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 25),
                            FadeTransition(
                              opacity: _fieldsFadeAnimation,
                              child: Column(
                                children: [
                                  TextField(
                                    controller: emailController,
                                    decoration: InputDecoration(
                                      labelText: "Email",
                                      prefixIcon: const Icon(Icons.email),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  TextField(
                                    controller: passwordController,
                                    obscureText: obscurePassword,
                                    decoration: InputDecoration(
                                      labelText: "Password",
                                      prefixIcon: const Icon(Icons.lock),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          obscurePassword
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            obscurePassword = !obscurePassword;
                                          });
                                        },
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {},
                                      child: const Text("Forgot Password?"),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: loginUser,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        backgroundColor: Colors.green.shade700,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text(
                                        "Login",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text("New to EchoThread? "),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const RegisterScreen(),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          "Register",
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}