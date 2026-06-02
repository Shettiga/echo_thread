import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  String selectedRole = 'Donor';
  bool obscurePassword = true;

  final nameController = TextEditingController();
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

  bool _isLoading = false;

  Future<void> registerUser() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'role': selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      FocusScope.of(context).unfocus();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration Successful 🎉'),
          backgroundColor: Colors.green,
        ),
      );


      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'Registration Failed';
      if (e.code == 'email-already-in-use') message = 'Email already exists';
      if (e.code == 'weak-password') message = 'Weak password';
      _shakeController.forward(from: 0.0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      _shakeController.forward(from: 0.0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
  }

  @override
  void dispose() {
    _controller.dispose();
    _bgController.dispose();
    _shakeController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Widget _buildGlowBlob({required double size, required List<Color> colors}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }

  Widget _buildStatusChip({required IconData icon, required String label}) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        final pulse = 1 + (math.sin(_bgController.value * math.pi * 2) * 0.03);
        return Transform.scale(
          scale: pulse,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white.withOpacity(0.18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.18),
            Colors.white.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.08),
                ],
              ),
            ),
            child: const Icon(Icons.person_add, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create an account',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.94),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Join donors, NGOs and volunteers — get started now.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.76),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          final gradientShift = _bgController.value;

          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: const [
                      Color(0xFF123B26),
                      Color(0xFF1D6B31),
                      Color(0xFF57B65A),
                      Color(0xFFB5E6B0),
                    ],
                    begin: Alignment(-1.0 + (gradientShift * 0.12), -1.0),
                    end: Alignment(1.0, 1.0 - (gradientShift * 0.12)),
                  ),
                ),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0.14,
                  child: CustomPaint(
                    painter: _RegisterTexturePainter(progress: _bgController.value),
                  ),
                ),
              ),
              Positioned.fill(
                child: Stack(
                  children: [
                    Positioned(
                      left: -60 + _bgAnim1.value,
                      top: -40 + (_bgAnim2.value / 2),
                      child: _buildGlowBlob(
                        size: 240,
                        colors: [
                          Colors.white.withOpacity(0.09),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    Positioned(
                      right: -80 - _bgAnim2.value,
                      top: 110 + (_bgAnim3.value / 3),
                      child: _buildGlowBlob(
                        size: 280,
                        colors: [
                          const Color(0xFF8EE08E).withOpacity(0.16),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    Positioned(
                      right: 16 + _bgAnim3.value,
                      bottom: -70 - (_bgAnim1.value / 2),
                      child: _buildGlowBlob(
                        size: 320,
                        colors: [
                          const Color(0xFFE8F5E9).withOpacity(0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FadeTransition(
                              opacity: _cardFadeAnimation,
                              child: ScaleTransition(
                                scale: _cardScaleAnimation,
                                child: _buildHeroStrip(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            FadeTransition(
                              opacity: _cardFadeAnimation,
                              child: ScaleTransition(
                                scale: _cardScaleAnimation,
                                child: AnimatedBuilder(
                                  animation: _shakeController,
                                  builder: (context, child) {
                                    final offsetX = math.sin(
                                      _shakeController.value * math.pi * 4,
                                    ) * 8.0 * (1 - _shakeController.value);
                                    return Transform.translate(
                                      offset: Offset(offsetX, 0),
                                      child: child,
                                    );
                                  },
                                  child: Card(
                                    elevation: 0,
                                    color: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(30),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 16,
                                          sigmaY: 16,
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.white.withOpacity(0.16),
                                                Colors.white.withOpacity(0.08),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(30),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.2),
                                              width: 1.2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.18),
                                                blurRadius: 28,
                                                offset: const Offset(0, 16),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.fromLTRB(
                                            24,
                                            24,
                                            24,
                                            22,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              RotationTransition(
                                                turns: _logoRotateAnimation,
                                                child: ScaleTransition(
                                                  scale: _logoScaleAnimation,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(16),
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      gradient: RadialGradient(
                                                        colors: [
                                                          Colors.white.withOpacity(0.32),
                                                          Colors.white.withOpacity(0.08),
                                                        ],
                                                      ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.person_add,
                                                      color: Colors.white,
                                                      size: 84,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              const Text(
                                                'Create Account',
                                                style: TextStyle(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Join the movement — register to donate or volunteer',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.82),
                                                  height: 1.35,
                                                ),
                                              ),
                                              const SizedBox(height: 18),
                                              Wrap(
                                                alignment: WrapAlignment.center,
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  _buildStatusChip(icon: Icons.people, label: 'Community'),
                                                  _buildStatusChip(icon: Icons.lock, label: 'Secure'),
                                                  _buildStatusChip(icon: Icons.track_changes, label: 'Trackable'),
                                                ],
                                              ),
                                              const SizedBox(height: 20),
                                              FadeTransition(
                                                opacity: _fieldsFadeAnimation,
                                                child: Column(
                                                  children: [
                                                    TextField(
                                                      controller: nameController,
                                                      style: const TextStyle(color: Colors.white),
                                                      cursorColor: Colors.white,
                                                      decoration: InputDecoration(
                                                        labelText: 'Full Name',
                                                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.78)),
                                                        prefixIcon: const Icon(Icons.person, color: Colors.white),
                                                        filled: true,
                                                        fillColor: Colors.white.withOpacity(0.09),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(14),
                                                          borderSide: const BorderSide(color: Colors.white, width: 1.2),
                                                        ),
                                                        enabledBorder: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(14),
                                                          borderSide: BorderSide(color: Colors.white.withOpacity(0.14)),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    TextField(
                                                      controller: emailController,
                                                      keyboardType: TextInputType.emailAddress,
                                                      style: const TextStyle(color: Colors.white),
                                                      cursorColor: Colors.white,
                                                      decoration: InputDecoration(
                                                        labelText: 'Email',
                                                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.78)),
                                                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.white),
                                                        filled: true,
                                                        fillColor: Colors.white.withOpacity(0.09),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(14),
                                                          borderSide: const BorderSide(color: Colors.white, width: 1.2),
                                                        ),
                                                        enabledBorder: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(14),
                                                          borderSide: BorderSide(color: Colors.white.withOpacity(0.14)),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    TextField(
                                                      controller: passwordController,
                                                      obscureText: obscurePassword,
                                                      style: const TextStyle(color: Colors.white),
                                                      cursorColor: Colors.white,
                                                      decoration: InputDecoration(
                                                        labelText: 'Password',
                                                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.78)),
                                                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white),
                                                        filled: true,
                                                        fillColor: Colors.white.withOpacity(0.09),
                                                        suffixIcon: IconButton(
                                                          icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.white),
                                                          onPressed: () {
                                                            setState(() {
                                                              obscurePassword = !obscurePassword;
                                                            });
                                                          },
                                                        ),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(14),
                                                          borderSide: const BorderSide(color: Colors.white, width: 1.2),
                                                        ),
                                                        enabledBorder: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(14),
                                                          borderSide: BorderSide(color: Colors.white.withOpacity(0.14)),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    DropdownButtonFormField(
                                                      value: selectedRole,
                                                      items: const [
                                                        DropdownMenuItem(value: 'Donor', child: Text('Donor')),
                                                        DropdownMenuItem(value: 'NGO', child: Text('NGO')),
                                                        DropdownMenuItem(value: 'Volunteer', child: Text('Volunteer')),
                                                      ],
                                                      onChanged: (value) {
                                                        setState(() {
                                                          selectedRole = value.toString();
                                                        });
                                                      },
                                                      decoration: InputDecoration(
                                                        labelText: 'Select Role',
                                                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.78)),
                                                        filled: true,
                                                        fillColor: Colors.white.withOpacity(0.06),
                                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white, width: 1.2)),
                                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.14))),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 18),
                                                    SizedBox(
                                                      width: double.infinity,
                                                      child: GestureDetector(
                                                        onTap: _isLoading ? null : () => registerUser(),
                                                        child: AnimatedContainer(
                                                          duration: const Duration(milliseconds: 300),
                                                          height: 54,
                                                          decoration: BoxDecoration(
                                                            gradient: _isLoading
                                                                ? LinearGradient(colors: [Colors.green.shade700.withOpacity(0.9), Colors.green.shade500.withOpacity(0.9)])
                                                                : const LinearGradient(colors: [Color(0xFF0F4F22), Color(0xFF67C56A), Color(0xFFB6E6B2)], begin: Alignment.centerLeft, end: Alignment.centerRight),
                                                            borderRadius: BorderRadius.circular(16),
                                                            boxShadow: [
                                                              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 14, offset: const Offset(0, 8)),
                                                            ],
                                                          ),
                                                          child: Center(
                                                            child: AnimatedSwitcher(
                                                              duration: const Duration(milliseconds: 250),
                                                              child: _isLoading
                                                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                                                                  : const Text('Create Account', key: ValueKey('register_text'), style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                                                            ),
                                                          ),
                                                        ),
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
            ],
          );
        },
      ),
    );
  }
}

class _RegisterTexturePainter extends CustomPainter {
  _RegisterTexturePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()..color = Colors.white.withOpacity(0.06)..strokeWidth = 1;
    for (var i = 0; i < 7; i++) {
      final y = size.height * (i / 7);
      canvas.drawLine(Offset(0, y + (math.sin(progress * 2 * math.pi + i) * 6)), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RegisterTexturePainter oldDelegate) => oldDelegate.progress != progress;
}
