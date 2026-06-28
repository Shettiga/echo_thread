import 'package:flutter/material.dart';
import 'donate_clothes_screen.dart';
import 'track_donation_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'package:echo_thread/widgets/navigation_drawer.dart';
import 'package:echo_thread/services/theme_service.dart';

class DonorDashboard extends StatefulWidget {
  const DonorDashboard({super.key});

  @override
  State<DonorDashboard> createState() => _DonorDashboardState();
}

class _DonorDashboardState extends State<DonorDashboard>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String userName = "Loading...";
  String userEmail = "";
  String userRole = "Donor";
  String? profileImage;
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
          userEmail = data.data()?['email'] ?? user.email ?? "";
          userRole = data.data()?['role'] ?? "Donor";
          profileImage = data.data()?['profileImage'];
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
  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF2E7D32);
    final user = FirebaseAuth.instance.currentUser;
    final isDark = ThemeService().isDark(context);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white.withOpacity(0.9) : Colors.black87;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppNavigationDrawer(currentRoute: 'dashboard'),
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F7F5),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 HEADER (Modern Green Banner)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
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
                      color: themeColor.withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        );
                        getUserName(); // Refresh details when returning from profile
                      },
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        backgroundImage: profileImage != null && profileImage!.isNotEmpty
                            ? NetworkImage(profileImage!)
                            : null,
                        child: profileImage == null || profileImage!.isEmpty
                            ? const Icon(Icons.person, color: Color(0xFF2E7D32))
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Donor Dashboard",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userRole,
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
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
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
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
                      if (snapshot.hasError) {
                        debugPrint("[DONOR_DASHBOARD_STREAM_ERROR] Error: ${snapshot.error}");
                      }
                      if (snapshot.hasData) {
                        debugPrint("[DONOR_DASHBOARD_STREAM_DATA] Received docs count: ${snapshot.data!.docs.length}");
                      }
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
                        co2Saved = totalGarments * 5.5; // 5.5kg of CO2 per garment
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

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "Quick Actions",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
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
    final isDark = ThemeService().isDark(context);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white.withOpacity(0.9) : Colors.black87;
    final textSecondary = isDark ? Colors.white70 : Colors.black45;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
        getUserName(); // Refresh state upon return
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: textSecondary,
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
    final isDark = ThemeService().isDark(context);
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
          style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w500),
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
    final user = FirebaseAuth.instance.currentUser;
    final isDark = ThemeService().isDark(context);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white.withOpacity(0.9) : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F7F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: isDark ? Colors.white70 : themeColor),
        title: Text(
          "Impact Report",
          style: TextStyle(color: isDark ? Colors.white : themeColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('donations')
            .where('donorId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint("[SUSTAINABILITY_REPORT_STREAM_ERROR] Error: ${snapshot.error}");
            return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: textPrimary)));
          }
          if (snapshot.hasData) {
            debugPrint("[SUSTAINABILITY_REPORT_STREAM_DATA] Received docs count: ${snapshot.data!.docs.length}");
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          int totalDonations = 0;
          int totalClothes = 0;
          int pending = 0;
          int accepted = 0;
          int assigned = 0;
          int pickedUp = 0;
          int delivered = 0;
          int distributed = 0;

          if (snapshot.hasData) {
            final docs = snapshot.data!.docs;
            totalDonations = docs.length;
            for (var doc in docs) {
              final d = doc.data() as Map<String, dynamic>;
              final int qty = int.tryParse(d['quantity']?.toString() ?? '1') ?? 1;
              totalClothes += qty;
              final String status = d['status'] ?? 'Pending';
              if (status == 'Pending') {
                pending++;
              } else if (status == 'Accepted' || status == 'Accepted by NGO') {
                accepted++;
              } else if (status == 'Assigned' || status == 'Assigned to Volunteer' || status == 'Accepted by Volunteer') {
                assigned++;
              } else if (status == 'Picked Up') {
                pickedUp++;
              } else if (status == 'Delivered') {
                delivered++;
              } else if (status == 'Distributed') {
                distributed++;
              }
            }
          }

          // Environmental impact metrics (CO2: 5.5kg, Water: 2700L, landfill: 0.3kg per garment)
          double co2Saved = totalClothes * 5.5;
          double waterSaved = totalClothes * 2700.0;
          double landfillSaved = totalClothes * 0.3;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.eco_rounded, size: 64, color: themeColor),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    "Your Dynamic Fashion Impact",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                ),
                const SizedBox(height: 24),

                // Core Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(context, "Donations Made", totalDonations.toString(), Icons.volunteer_activism, themeColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(context, "Clothes Donated", totalClothes.toString(), Icons.checkroom, themeColor),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Status Summary
                Text(
                  "Donation Status Summary",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildStatusRow(context, "Pending Review", pending, Colors.orange),
                      _buildStatusRow(context, "Accepted by NGO", accepted, Colors.blue),
                      _buildStatusRow(context, "Assigned to Volunteer", assigned, Colors.indigo),
                      _buildStatusRow(context, "In Transit (Picked Up)", pickedUp, Colors.purple),
                      _buildStatusRow(context, "Delivered to NGO", delivered, Colors.green),
                      _buildStatusRow(context, "Distributed to Needy", distributed, Colors.teal),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Environmental Impact section
                Text(
                  "Estimated Environmental Impact",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const SizedBox(height: 12),
                _buildImpactMetric(context, "CO₂ Saved", "${co2Saved.toStringAsFixed(1)} kg", "Avoided carbon footprint from new textile production.", themeColor),
                _buildImpactMetric(context, "Water Saved", "${waterSaved.toStringAsFixed(0)} Liters", "Saved water by reusing textiles instead of manufacturing new ones.", themeColor),
                _buildImpactMetric(context, "Landfill Prevented", "${landfillSaved.toStringAsFixed(1)} kg", "Amount of waste directly diverted from open landfills.", themeColor),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String val, IconData icon, Color color) {
    final isDark = ThemeService().isDark(context);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(val, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context, String title, int count, Color color) {
    final isDark = ThemeService().isDark(context);
    final textPrimary = isDark ? Colors.white.withOpacity(0.9) : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontSize: 13, color: textPrimary)),
            ],
          ),
          Text(
            count.toString(),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactMetric(BuildContext context, String label, String value, String desc, Color color) {
    final isDark = ThemeService().isDark(context);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white.withOpacity(0.9) : Colors.black87;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: color, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                    Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: color)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}