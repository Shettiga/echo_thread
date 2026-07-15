import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'donor_dashboard.dart';
import 'ngo_dashboard.dart';
import 'volunteer_dashboard.dart';
import 'admin_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _backgroundGlowAnimation;
  late final Animation<double> _cardFadeAnimation;
  late final Animation<double> _cardScaleAnimation;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _logoRotateAnimation;
  late final Animation<Offset> _titleSlideAnimation;
  late final Animation<double> _titleFadeAnimation;
  late final Animation<double> _subtitleFadeAnimation;
  late final Animation<double> _progressFadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();

    _backgroundGlowAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _cardFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    _cardScaleAnimation = Tween<double>(
      begin: 0.82,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.75, curve: Curves.elasticOut),
      ),
    );

    _logoScaleAnimation = Tween<double>(
      begin: 0.55,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _logoRotateAnimation = Tween<double>(
      begin: -0.08,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.12, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.38, 0.82, curve: Curves.easeOutCubic),
      ),
    );

    _titleFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.8, curve: Curves.easeOut),
    );

    _subtitleFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.52, 0.88, curve: Curves.easeOut),
    );

    _progressFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.68, 1.0, curve: Curves.easeOut),
    );

    Timer(const Duration(seconds: 4), () async {
      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (doc.exists && doc.data() != null) {
            final role = doc.data()?['role'];
            if (mounted) {
              _navigateToDashboard(role);
              return;
            }
          }
        } catch (e) {
          debugPrint('[SPLASH] Persistent login verification error: $e');
        }
      }
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    });
  }

  void _navigateToDashboard(String? role) {
    final String roleLower = (role ?? '').toString().toLowerCase();
    if (roleLower == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    } else if (roleLower == 'donor') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DonorDashboard()),
      );
    } else if (roleLower == 'ngo') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NGODashboard()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VolunteerDashboard()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildGlow({
    required Alignment alignment,
    required double size,
    required Color color,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(
            alpha: 0.18 + (0.12 * _backgroundGlowAnimation.value),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F3D2E),
              Color(0xFF1B5E20),
              Color(0xFF43A047),
              Color(0xFF93D18B),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SplashTexturePainter(
                      progress: _controller.value,
                    ),
                  ),
                ),
                _buildGlow(
                  alignment: const Alignment(-1.05, -0.95),
                  size: 220 + (_backgroundGlowAnimation.value * 40),
                  color: const Color(0xFFB9F6CA),
                ),
                _buildGlow(
                  alignment: const Alignment(1.1, -0.1),
                  size: 180 + (_backgroundGlowAnimation.value * 30),
                  color: const Color(0xFFE8F5E9),
                ),
                _buildGlow(
                  alignment: const Alignment(0.8, 1.0),
                  size: 260 + (_backgroundGlowAnimation.value * 50),
                  color: const Color(0xFF66BB6A),
                ),
                Center(
                  child: FadeTransition(
                    opacity: _cardFadeAnimation,
                    child: ScaleTransition(
                      scale: _cardScaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 28,
                        ),
                        constraints: const BoxConstraints(maxWidth: 320),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 28,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RotationTransition(
                              turns: _logoRotateAnimation,
                              child: ScaleTransition(
                                scale: _logoScaleAnimation,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 24,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      height: 112,
                                      width: 112,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            SlideTransition(
                              position: _titleSlideAnimation,
                              child: FadeTransition(
                                opacity: _titleFadeAnimation,
                                child: const Text(
                                  'EchoThread',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 1.3,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            FadeTransition(
                              opacity: _subtitleFadeAnimation,
                              child: const Text(
                                'Reuse • Donate • Empower',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.4,
                                  color: Colors.white70,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 26),
                            FadeTransition(
                              opacity: _progressFadeAnimation,
                              child: Column(
                                children: [
                                  const SizedBox(
                                    width: 168,
                                    child: LinearProgressIndicator(
                                      minHeight: 4,
                                      backgroundColor: Color(0x33FFFFFF),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    "Your donation starts someone's new story.",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.82),
                                      letterSpacing: 0.5,
                                    ),
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
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SplashTexturePainter extends CustomPainter {
  _SplashTexturePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final verticalOffset = size.height * 0.12 * progress;

    for (var index = 0; index < 7; index++) {
      final dx = (size.width / 7) * index;
      final path = Path()
        ..moveTo(dx, size.height)
        ..quadraticBezierTo(
          dx + size.width * 0.08,
          size.height * 0.72 - verticalOffset,
          dx + size.width * 0.18,
          size.height * 0.48 - (verticalOffset * 0.45),
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SplashTexturePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}