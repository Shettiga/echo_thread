import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'volunteer_map_screen.dart';
import 'package:echo_thread/config.dart';
import 'package:echo_thread/widgets/navigation_drawer.dart';
import 'package:echo_thread/widgets/profile_image_dialog.dart';
import 'package:echo_thread/services/app_localizations.dart';

class VolunteerDashboard extends StatefulWidget {
  const VolunteerDashboard({super.key});

  @override
  State<VolunteerDashboard> createState() => _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String userName = "Loading...";
  String userEmail = "";
  String userRole = "Volunteer";
  String? profileImage;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    getUserName();
    _tabController = TabController(length: 2, vsync: this);

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
    _tabController.dispose();
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
          userEmail = data.data()?['email'] ?? user.email ?? "";
          userRole = data.data()?['role'] ?? "Volunteer";
          profileImage = data.data()?['profileImage'];
        });
      }
    }
  }

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _updateTaskStatus(String donationId, String nextStatus) async {
    final user = FirebaseAuth.instance.currentUser;
    final String uid = user?.uid ?? 'unknown';
    try {
      debugPrint("[EXPRESS_API_POST_START] UID: $uid, Endpoint: /api/update-donation, DocID: $donationId");
      final response = await http.post(
        Uri.parse('${AppConfig.backendUrl}/api/update-donation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'donationId': donationId,
          'status': nextStatus,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to update task status.');
      }
      debugPrint("[EXPRESS_API_POST_SUCCESS] UID: $uid, Endpoint: /api/update-donation, DocID: $donationId, Response: Task status updated to $nextStatus successfully");

      if (!mounted) return;
      String toastMsg = "";
      if (nextStatus == 'Accepted by Volunteer') {
        toastMsg = "Task Accepted Successfully! 📋";
      } else if (nextStatus == 'Picked Up') {
        toastMsg = "Marked as Picked Up! Drive safely! 🚗";
      } else {
        toastMsg = "Garments delivered to the NGO hub! Thank you! 🎉";
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(toastMsg),
          backgroundColor: Colors.blue.shade900,
        ),
      );
    } on FirebaseException catch (e) {
      debugPrint("[FIRESTORE_WRITE_ERROR] UID: $uid, Collection: donations, DocID: $donationId, Exception: ${e.code} - ${e.message}");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Firebase Error: ${e.message}"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      debugPrint("Error updating status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF1565C0);
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white.withOpacity(0.9) : Colors.black87;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppNavigationDrawer(currentRoute: 'dashboard'),
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF0F4F8),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // 🔹 HEADER
              Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
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
                      color: themeColor.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
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
                      onTap: () {
                        showProfileImageDialog(
                          context: context,
                          imageUrl: profileImage,
                          userName: userName,
                          userRole: userRole,
                          fallbackIcon: Icons.volunteer_activism_outlined,
                          themeColor: Colors.blue,
                          onProfileUpdated: getUserName,
                        );
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        backgroundImage: profileImage != null && profileImage!.isNotEmpty
                            ? NetworkImage(profileImage!)
                            : null,
                        child: profileImage == null || profileImage!.isEmpty
                            ? const Icon(Icons.volunteer_activism_outlined, color: Colors.blue)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.translate('dashboard'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.translate('role') + ": " + userRole,
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 🔹 TAB BAR FOR ACTIVE / COMPLETED TASKS
              TabBar(
                controller: _tabController,
                labelColor: themeColor,
                unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,
                indicatorColor: themeColor,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: [
                  Tab(text: context.translate('active_actions')),
                  Tab(text: context.translate('completed_tasks')),
                ],
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
                    if (snapshot.hasError) {
                      debugPrint("[VOLUNTEER_DASHBOARD_STREAM_ERROR] Error: ${snapshot.error}");
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.blue));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _buildEmptyListWidget(context.translate('active_actions')),
                          _buildEmptyListWidget(context.translate('completed_tasks')),
                        ],
                      );
                    }

                    final allDocs = snapshot.data!.docs;

                    // Filter active tasks
                    final activeTasks = allDocs.where((doc) {
                      final status = (doc.data() as Map<String, dynamic>)['status'] ?? '';
                      return status == 'Assigned to Volunteer' ||
                          status == 'Assigned' ||
                          status == 'Accepted by Volunteer' ||
                          status == 'Picked Up';
                    }).toList();

                    // Filter completed/delivered tasks
                    final completedTasks = allDocs.where((doc) {
                      final status = (doc.data() as Map<String, dynamic>)['status'] ?? '';
                      return status == 'Delivered' || status == 'Completed' || status == 'Distributed';
                    }).toList();

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildActiveTasksList(activeTasks, cardBg, textPrimary, textSecondary),
                        _buildCompletedTasksList(completedTasks, cardBg, textPrimary, textSecondary),
                      ],
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

  Widget _buildEmptyListWidget(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            "No $title found.",
            style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTasksList(List<QueryDocumentSnapshot> tasks, Color cardBg, Color textPrimary, Color textSecondary) {
    if (tasks.isEmpty) {
      return _buildEmptyListWidget(context.translate('active_actions'));
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
        final String donorId = data['donorId'] ?? "";
        final String donor = data['donorName'] ?? "Donor";
        final String address = data['location'] ?? "No address";
        final String pickupDate = data['pickupDate'] ?? "Soon";
        final String? photoUrl = data['imageUrl'];
        final String assignedDate = data['assignedAt'] != null
            ? (data['assignedAt'] as Timestamp).toDate().toString().substring(0, 10)
            : pickupDate;

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          elevation: 0,
          color: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.blue.withOpacity(0.15), width: 1.2),
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                    _buildStatusPill(status),
                  ],
                ),
                const Divider(height: 24),

                // Fetch Donor details
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(donorId).get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const Text("Loading donor details...", style: TextStyle(fontSize: 12, color: Colors.grey));
                    }
                    final uData = userSnapshot.data?.data() as Map<String, dynamic>?;
                    final String dPhone = uData?['phone'] ?? "No Phone";
                    final String dEmail = uData?['email'] ?? "No Email";

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${context.translate('donor_name')}: $donor",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text("📞 ${context.translate('phone')}: $dPhone", style: TextStyle(fontSize: 12.5, color: textSecondary)),
                        Text("✉️ ${context.translate('email')}: $dEmail", style: TextStyle(fontSize: 12.5, color: textSecondary)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  "${context.translate('pickup_address')}: $address",
                  style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  "${context.translate('date')}: $assignedDate",
                  style: TextStyle(color: textSecondary, fontSize: 12.5),
                ),

                // Display Photo if available
                if (photoUrl != null && photoUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      photoUrl,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 140,
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 140,
                          color: Colors.grey.shade100,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(color: Colors.blue),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (status == 'Assigned to Volunteer' || status == 'Assigned')
                      ElevatedButton.icon(
                        onPressed: () => _updateTaskStatus(taskId, 'Accepted by Volunteer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.thumb_up_alt_outlined, color: Colors.white, size: 16),
                        label: Text(context.translate('accept_task'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )
                    else if (status == 'Accepted by Volunteer') ...[
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VolunteerMapScreen(
                                donationId: taskId,
                                donorName: donor,
                                donorAddress: address,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.blue.shade700),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: Icon(Icons.map_outlined, color: Colors.blue.shade700, size: 16),
                        label: Text(context.translate('track_route'), style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _updateTaskStatus(taskId, 'Picked Up'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.airport_shuttle_outlined, color: Colors.white, size: 16),
                        label: Text(context.translate('mark_pickup'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )
                    ] else if (status == 'Picked Up') ...[
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VolunteerMapScreen(
                                donationId: taskId,
                                donorName: donor,
                                donorAddress: address,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.blue.shade700),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: Icon(Icons.map_outlined, color: Colors.blue.shade700, size: 16),
                        label: Text(context.translate('track_route'), style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _updateTaskStatus(taskId, 'Delivered'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                        label: Text(context.translate('mark_delivered'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )
                    ]
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletedTasksList(List<QueryDocumentSnapshot> tasks, Color cardBg, Color textPrimary, Color textSecondary) {
    if (tasks.isEmpty) {
      return _buildEmptyListWidget(context.translate('completed_tasks'));
    }

    return ListView.builder(
      itemCount: tasks.length,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      itemBuilder: (context, index) {
        final taskDoc = tasks[index];
        final taskId = taskDoc.id;
        final data = taskDoc.data() as Map<String, dynamic>;
        final String status = data['status'] ?? "Completed";
        final String clothes = data['clothes'] ?? "Clothes";
        final String qty = data['quantity']?.toString() ?? "1";
        final String donor = data['donorName'] ?? "Donor";
        final String address = data['location'] ?? "No address";
        final String pickupDate = data['pickupDate'] ?? "N/A";
        final String ngo = data['ngoName'] ?? "Unassigned NGO";

        String completionDate = "N/A";
        if (data['completedAt'] != null) {
          final date = (data['completedAt'] as Timestamp).toDate();
          completionDate = "${date.day}/${date.month}/${date.year}";
        } else if (data['deliveredAt'] != null) {
          final date = (data['deliveredAt'] as Timestamp).toDate();
          completionDate = "${date.day}/${date.month}/${date.year}";
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          elevation: 0,
          color: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.green.withOpacity(0.15), width: 1.2),
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                    _buildStatusPill(status),
                  ],
                ),
                const Divider(height: 24),
                Text(
                  "${context.translate('donation_id')}: $taskId",
                  style: const TextStyle(color: Colors.grey, fontSize: 11.5, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  "${context.translate('donor_name')}: $donor",
                  style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "${context.translate('ngo')}: $ngo",
                  style: TextStyle(color: textSecondary, fontSize: 12.5),
                ),
                const SizedBox(height: 4),
                Text(
                  "${context.translate('pickup_address')}: $address",
                  style: TextStyle(color: textSecondary, fontSize: 12.5),
                ),
                const SizedBox(height: 4),
                Text(
                  "${context.translate('date')}: $pickupDate",
                  style: TextStyle(color: textSecondary, fontSize: 12.5),
                ),
                const SizedBox(height: 4),
                Text(
                  "${context.translate('completion_date')}: $completionDate",
                  style: TextStyle(color: Colors.green.shade800, fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg = Colors.grey.shade100;
    Color text = Colors.grey;

    switch (status) {
      case "Assigned to Volunteer":
      case "Assigned":
        bg = Colors.indigo.shade50;
        text = Colors.indigo.shade800;
        break;
      case "Accepted by Volunteer":
        bg = Colors.blue.shade50;
        text = Colors.blue.shade800;
        break;
      case "Picked Up":
        bg = Colors.purple.shade50;
        text = Colors.purple.shade800;
        break;
      case "Delivered":
      case "Completed":
      case "Distributed":
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