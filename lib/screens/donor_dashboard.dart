import 'package:flutter/material.dart';
import 'donate_clothes_screen.dart';
import 'track_donation_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class DonorDashboard extends StatefulWidget {
  const DonorDashboard({super.key});

  @override
  State<DonorDashboard> createState() => _DonorDashboardState();
}

class _DonorDashboardState extends State<DonorDashboard>
    with SingleTickerProviderStateMixin {
  String userName = "Loading...";
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    getUserName();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var data = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          userName = data.data()?['name'] ?? "User";
        });
      }
    }
  }

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF2E7D32);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 HEADER (Modern Green Banner)
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [themeColor, const Color(0xFF43A047)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hello, $userName 👋",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Ready to make an impact today?",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ProfileScreen()),
                            );
                          },
                          child: const CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, color: Color(0xFF2E7D32)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: () => logout(context),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 🌍 DYNAMIC IMPACT CARD (Real-time Firestore aggregates)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('donations')
                        .where('donorId', isEqualTo: user?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      int totalGarments = 0;
                      int peopleHelped = 0;
                      double co2Saved = 0.0;

                      if (snapshot.hasData) {
                        for (var doc in snapshot.data!.docs) {
                          var d = doc.data() as Map<String, dynamic>;
                          int qty = int.tryParse(d['quantity']?.toString() ?? '1') ?? 1;
                          totalGarments += qty;
                          if (d['status'] == 'Delivered' || d['status'] == 'Distributed') {
                            peopleHelped += (qty * 0.85).round();
                          }
                        }
                        co2Saved = totalGarments * 0.55; // 0.55kg of CO2 per garment
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ImpactItem(
                            title: "Clothes Donated",
                            value: totalGarments.toString(),
                            icon: Icons.checkroom_outlined,
                          ),
                          ImpactItem(
                            title: "People Helped",
                            value: peopleHelped.toString(),
                            icon: Icons.favorite_border,
                          ),
                          ImpactItem(
                            title: "CO₂ Saved",
                            value: "${co2Saved.toStringAsFixed(1)}kg",
                            icon: Icons.eco_outlined,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 28),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "Quick Actions",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 🔹 GRID (Quick Actions)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      dashboardCard(
                        context,
                        Icons.add_box_outlined,
                        "Donate Clothes",
                        "Share clothes with people in need",
                        const DonateClothesScreen(),
                        const Color(0xFFC8E6C9),
                        themeColor,
                      ),
                      dashboardCard(
                        context,
                        Icons.local_shipping_outlined,
                        "Track Donation",
                        "View pickup & delivery status",
                        const TrackDonationScreen(),
                        const Color(0xFFBBDEFB),
                        const Color(0xFF1565C0),
                      ),
                      dashboardCard(
                        context,
                        Icons.eco_outlined,
                        "Impact Report",
                        "Textile reuse & sustainability info",
                        const SustainabilityReportScreen(),
                        const Color(0xFFFFE0B2),
                        const Color(0xFFE65100),
                      ),
                      dashboardCard(
                        context,
                        Icons.person_outline,
                        "Profile Settings",
                        "Manage personal credentials",
                        const ProfileScreen(),
                        const Color(0xFFE1BEE7),
                        const Color(0xFF6A1B9A),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget dashboardCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    Widget screen,
    Color bgTint,
    Color accentColor,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgTint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: accentColor),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🌍 IMPACT ITEM
class ImpactItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const ImpactItem({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF2E7D32), size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// 📌 SUSTAINABILITY REPORT SCREEN (Elegant replacement for placeholder)
class SustainabilityReportScreen extends StatelessWidget {
  const SustainabilityReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: themeColor),
        title: Text(
          "Impact Report",
          style: TextStyle(color: themeColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(Icons.eco_rounded, size: 80, color: themeColor),
            ),
            const SizedBox(height: 20),
            const Text(
              "Sustainable Fashion Impact",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Text(
              "Every single item of clothing you donate helps avoid landfill and minimizes the massive carbon footprint of textile manufacturing.",
              style: TextStyle(fontSize: 15, height: 1.4, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            _buildStatMetric("CO₂ Emissions Avoided", "5.5 kg per garment saved from production lines."),
            _buildStatMetric("Water Conservation", "Over 2,700 liters of water conserved by reuse."),
            _buildStatMetric("Landfill Reduction", "100% of cotton fabric fibers recycled/reused instead of thrown."),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Keep Donating!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatMetric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                const SizedBox(height: 3),
                Text(value, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          )
        ],
      ),
    );
  }
}