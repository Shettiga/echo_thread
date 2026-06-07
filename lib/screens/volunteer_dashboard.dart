import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class VolunteerDashboard extends StatefulWidget {
  const VolunteerDashboard({super.key});

  @override
  State<VolunteerDashboard> createState() => _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard>
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
      duration: const Duration(milliseconds: 700),
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
          userName = data.data()?['name'] ?? "Volunteer Portal";
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

  Future<void> _updateTaskStatus(String donationId, String nextStatus) async {
    await FirebaseFirestore.instance
        .collection('donations')
        .doc(donationId)
        .update({
      'status': nextStatus,
    });

    if (!mounted) return;
    String toastMsg = nextStatus == 'Picked Up'
        ? "Marked as Picked Up! Drive safely! 🚗"
        : "Garments delivered to the NGO hub! Thank you! 🎉";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(toastMsg),
        backgroundColor: Colors.blue.shade800,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF1565C0);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // 🔹 HEADER
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [themeColor, const Color(0xFF42A5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Ready to support community tasks?",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
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
                            backgroundColor: Colors.white,
                            child: Icon(Icons.volunteer_activism_outlined, color: Colors.blue),
                          ),
                        ),
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

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Icon(Icons.assignment_outlined, color: Colors.black54),
                    SizedBox(width: 8),
                    Text(
                      "Your Tasks",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 🔹 TASK STREAM FEED
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('donations')
                      .where('volunteerId', isEqualTo: user?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.blue));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              "All caught up! No assigned tasks.",
                              style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    }

                    final tasks = snapshot.data!.docs.where((doc) {
                      final status = (doc.data() as Map<String, dynamic>)['status'];
                      return status == 'Assigned' || status == 'Picked Up' || status == 'Delivered';
                    }).toList();

                    if (tasks.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              "All caught up! No active tasks.",
                              style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: tasks.length,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      itemBuilder: (context, index) {
                        final taskDoc = tasks[index];
                        final taskId = taskDoc.id;
                        final data = taskDoc.data() as Map<String, dynamic>;
                        final String status = data['status'] ?? "Pending";
                        final String clothes = data['clothes'] ?? "Clothes";
                        final String qty = data['quantity']?.toString() ?? "1";
                        final String donor = data['donorName'] ?? "Donor";
                        final String address = data['location'] ?? "No address";
                        final String pickupDate = data['pickupDate'] ?? "Soon";

                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.blue.withValues(alpha: 0.15), width: 1.2),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "$clothes (Qty: $qty)",
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    _buildStatusPill(status),
                                  ],
                                ),
                                const Divider(height: 24),
                                const Text(
                                  "NGO Message:",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    "Instructions: Please collect these clothes from donor $donor at their address on $pickupDate.",
                                    style: TextStyle(color: Colors.blue.shade900, fontSize: 12.5, height: 1.3),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  "Donor Address: $address",
                                  style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (status == 'Assigned')
                                      ElevatedButton.icon(
                                        onPressed: () => _updateTaskStatus(taskId, 'Picked Up'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue.shade700,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        icon: const Icon(Icons.airport_shuttle_outlined, color: Colors.white, size: 16),
                                        label: const Text("Mark as Picked Up", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      )
                                    else if (status == 'Picked Up')
                                      ElevatedButton.icon(
                                        onPressed: () => _updateTaskStatus(taskId, 'Delivered'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green.shade700,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                                        label: const Text("Mark as Delivered", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      )
                                    else
                                      const Row(
                                        children: [
                                          Icon(Icons.check, color: Colors.green),
                                          SizedBox(width: 4),
                                          Text(
                                            "Delivered to NGO hub",
                                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ],
                                      )
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg = Colors.grey.shade100;
    Color text = Colors.grey;

    switch (status) {
      case "Assigned":
        bg = Colors.blue.shade50;
        text = Colors.blue.shade800;
        break;
      case "Picked Up":
        bg = Colors.purple.shade50;
        text = Colors.purple.shade800;
        break;
      case "Delivered":
        bg = Colors.green.shade50;
        text = Colors.green.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}