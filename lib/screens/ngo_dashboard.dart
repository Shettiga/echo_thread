import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'package:echo_thread/config.dart';
import 'package:echo_thread/widgets/navigation_drawer.dart';
import 'package:echo_thread/services/theme_service.dart';
import 'package:echo_thread/widgets/profile_image_dialog.dart';
import 'package:echo_thread/services/app_localizations.dart';

class NGODashboard extends StatefulWidget {
  const NGODashboard({super.key});

  @override
  State<NGODashboard> createState() => _NGODashboardState();
}

class _NGODashboardState extends State<NGODashboard>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String userName = "Loading...";
  String userEmail = "";
  String userRole = "NGO";
  String userStatus = "Loading";
  String? profileImage;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    getUserName();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
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
          userName = data.data()?['name'] ?? "NGO Portal";
          userEmail = data.data()?['email'] ?? user.email ?? "";
          userRole = data.data()?['role'] ?? "NGO";
          userStatus = data.data()?['status'] ?? "Approved"; // default to Approved for compatibility
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

  Future<void> _acceptDonation(BuildContext context, String donationId) async {
    final user = FirebaseAuth.instance.currentUser;
    final String uid = user?.uid ?? 'unknown';
    try {
      debugPrint("[FIRESTORE_WRITE_START] UID: $uid, Collection: donations, DocID: $donationId");
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(donationId)
          .update({
        'status': 'Accepted by NGO',
        'ngoId': uid,
        'ngoName': userName,
        'acceptedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
      debugPrint("[FIRESTORE_WRITE_SUCCESS] UID: $uid, Collection: donations, DocID: $donationId, Response: Donation accepted successfully");

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Donation request accepted! 👍"),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseException catch (e) {
      debugPrint("[FIRESTORE_WRITE_ERROR] UID: $uid, Collection: donations, DocID: $donationId, Exception: ${e.code} - ${e.message}");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Firebase Error: ${e.message}"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      debugPrint("Error accepting donation: $e");
    }
  }

  Future<void> _rejectDonation(BuildContext context, String donationId) async {
    final user = FirebaseAuth.instance.currentUser;
    final String uid = user?.uid ?? 'unknown';
    try {
      debugPrint("[FIRESTORE_WRITE_START] UID: $uid, Collection: donations, DocID: $donationId");
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(donationId)
          .update({
        'status': 'Rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
      debugPrint("[FIRESTORE_WRITE_SUCCESS] UID: $uid, Collection: donations, DocID: $donationId, Response: Donation rejected successfully");

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Donation request rejected."),
          backgroundColor: Colors.redAccent,
        ),
      );
    } on FirebaseException catch (e) {
      debugPrint("[FIRESTORE_WRITE_ERROR] UID: $uid, Collection: donations, DocID: $donationId, Exception: ${e.code} - ${e.message}");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Firebase Error: ${e.message}"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      debugPrint("Error rejecting donation: $e");
    }
  }

  Future<void> _showAssignVolunteerSheet(BuildContext context, String donationId) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Assign a Volunteer",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Select an active volunteer to pick up this donation:",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'Volunteer')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.orange));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            "No active volunteers found 😔",
                            style: TextStyle(color: Colors.black45),
                          ),
                        ),
                      );
                    }

                    final volunteers = snapshot.data!.docs;

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: volunteers.length,
                      itemBuilder: (context, index) {
                        final vData = volunteers[index].data() as Map<String, dynamic>;
                        final vId = volunteers[index].id;
                        final vName = vData['name'] ?? "Volunteer";

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFFFE0B2),
                              backgroundImage: vData['profileImage'] != null && vData['profileImage'].toString().isNotEmpty
                                  ? NetworkImage(vData['profileImage'])
                                  : null,
                              child: vData['profileImage'] == null || vData['profileImage'].toString().isEmpty
                                  ? const Icon(Icons.person, color: Colors.orange)
                                  : null,
                            ),
                            title: Text(vName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(vData['email'] ?? ""),
                            trailing: const Icon(Icons.chevron_right, color: Colors.orange),
                            onTap: () async {
                              final user = FirebaseAuth.instance.currentUser;
                              final String uid = user?.uid ?? 'unknown';
                              try {
                                debugPrint("[EXPRESS_API_POST_START] UID: $uid, Endpoint: /api/update-donation, DocID: $donationId");
                                final response = await http.post(
                                  Uri.parse('${AppConfig.backendUrl}/api/update-donation'),
                                  headers: {'Content-Type': 'application/json'},
                                  body: jsonEncode({
                                    'donationId': donationId,
                                    'status': 'Assigned to Volunteer',
                                    'volunteerId': vId,
                                    'volunteerName': vName,
                                    'ngoId': uid,
                                    'ngoName': userName,
                                    'assignedAt': 'serverTimestamp',
                                  }),
                                ).timeout(const Duration(seconds: 10));

                                if (response.statusCode != 200) {
                                  throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to assign volunteer.');
                                }
                                debugPrint("[EXPRESS_API_POST_SUCCESS] UID: $uid, Endpoint: /api/update-donation, DocID: $donationId, Response: Volunteer assigned successfully");

                                if (!context.mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Volunteer assigned successfully"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } on FirebaseException catch (e) {
                                debugPrint("[FIRESTORE_WRITE_ERROR] UID: $uid, Collection: donations, DocID: $donationId, Exception: ${e.code} - ${e.message}");
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Firebase Error: ${e.message}"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } catch (e) {
                                debugPrint("Error assigning volunteer: $e");
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _distributeClothes(BuildContext context, String donationId) async {
    final user = FirebaseAuth.instance.currentUser;
    final String uid = user?.uid ?? 'unknown';
    try {
      debugPrint("[FIRESTORE_WRITE_START] UID: $uid, Collection: donations, DocID: $donationId");
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(donationId)
          .update({
        'status': 'Distributed',
        'distributedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
      debugPrint("[FIRESTORE_WRITE_SUCCESS] UID: $uid, Collection: donations, DocID: $donationId, Response: Clothes distributed successfully");

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Clothes marked as Distributed to the Needy! 🎁"),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseException catch (e) {
      debugPrint("[FIRESTORE_WRITE_ERROR] UID: $uid, Collection: donations, DocID: $donationId, Exception: ${e.code} - ${e.message}");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Firebase Error: ${e.message}"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      debugPrint("Error distributing clothes: $e");
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFFE65100);
    final isDark = ThemeService().isDark(context);

    if (userStatus == "Loading") {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFE65100)),
        ),
      );
    }

    if (userStatus.toLowerCase() == "pending" || userStatus.toLowerCase() == "rejected") {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFFF8F5),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: (userStatus.toLowerCase() == "pending" ? Colors.orange : Colors.red).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    userStatus.toLowerCase() == "pending" ? Icons.hourglass_empty : Icons.gpp_bad,
                    size: 64,
                    color: userStatus.toLowerCase() == "pending" ? Colors.orange : Colors.red,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  userStatus.toLowerCase() == "pending" 
                      ? "Account Pending Verification"
                      : "Account Rejected",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  userStatus.toLowerCase() == "pending"
                      ? "Your NGO profile is currently under review by EchoThread system administrators. We will notify you once your status is updated."
                      : "Your NGO request has been declined. Please contact support if you believe this is an error.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100)),
                    onPressed: () => logout(context),
                    child: const Text("Log Out", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppNavigationDrawer(currentRoute: 'dashboard'),
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFFF8F5),
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 HEADER
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [themeColor, const Color(0xFFFFA726)],
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                "Hello, $userName 👋",
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                userRole,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const SizedBox(),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          showProfileImageDialog(
                            context: context,
                            imageUrl: profileImage,
                            userName: userName,
                            userRole: userRole,
                            fallbackIcon: Icons.home_work_outlined,
                            themeColor: Colors.orange,
                            onProfileUpdated: getUserName,
                          );
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          backgroundImage: profileImage != null && profileImage!.isNotEmpty
                              ? NetworkImage(profileImage!)
                              : null,
                          child: profileImage == null || profileImage!.isEmpty
                              ? const Icon(Icons.home_work_outlined, color: Colors.orange)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                    ],
                  )
                ],
              ),
            ),

            // 🔹 TABS FOR DONATION MANAGEMENT
            TabBar(
              controller: _tabController,
              labelColor: themeColor,
              unselectedLabelColor: Colors.black38,
              indicatorColor: themeColor,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(text: "Active Actions"),
                Tab(text: "History"),
              ],
            ),

            // 🔹 TAB VIEW LISTS
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('donations').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    debugPrint("[NGO_DASHBOARD_STREAM_ERROR] Error: ${snapshot.error}");
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (snapshot.hasData) {
                    debugPrint("[NGO_DASHBOARD_STREAM_DATA] Received docs count: ${snapshot.data!.docs.length}");
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.orange));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No donations available."));
                  }

                  final allDonations = snapshot.data!.docs;

                  // Sort in-memory by creation time descending
                  allDonations.sort((a, b) {
                    var aData = a.data() as Map<String, dynamic>;
                    var bData = b.data() as Map<String, dynamic>;
                    Timestamp aTime = aData['createdAt'] ?? Timestamp.now();
                    Timestamp bTime = bData['createdAt'] ?? Timestamp.now();
                    return bTime.compareTo(aTime);
                  });

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      // Active Tab (Pending, Accepted by NGO, Assigned, Picked Up, Delivered)
                      _buildDonationList(
                        allDonations.where((doc) {
                          final status = (doc.data() as Map<String, dynamic>)['status'];
                          return status != 'Distributed' && status != 'Rejected';
                        }).toList(),
                        isActiveTab: true,
                      ),
                      // History Tab (Distributed, Rejected)
                      _buildDonationList(
                        allDonations.where((doc) {
                          final status = (doc.data() as Map<String, dynamic>)['status'];
                          return status == 'Distributed' || status == 'Rejected';
                        }).toList(),
                        isActiveTab: false,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationList(List<QueryDocumentSnapshot> docs, {required bool isActiveTab}) {
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActiveTab ? Icons.assignment_outlined : Icons.done_all_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              isActiveTab ? "No active donations to manage" : "No donation history found",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white.withOpacity(0.9) : Colors.black87;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;

    return ListView.builder(
      itemCount: docs.length,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      itemBuilder: (context, index) {
        final dDoc = docs[index];
        final dId = dDoc.id;
        final data = dDoc.data() as Map<String, dynamic>;
        final String status = data['status'] ?? "Pending";
        final String clothes = data['clothes'] ?? "Clothes";
        final String qty = data['quantity']?.toString() ?? "1";
        final String donor = data['donorName'] ?? "Donor";
        final String location = data['location'] ?? "Unknown";
        final String? photoUrl = data['imageUrl'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          color: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.orange.withOpacity(0.15), width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                const SizedBox(height: 10),
                Text(
                  "${context.translate('donor_name')}: $donor",
                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.w500, fontSize: 13.5),
                ),
                const SizedBox(height: 4),
                Text(
                  "${context.translate('pickup_address')}: $location",
                  style: TextStyle(color: textSecondary, fontSize: 12.5),
                ),

                // Render Donation photo if available (Interactive Zoom Dialog)
                if (photoUrl != null && photoUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InteractiveViewer(
                              panEnabled: true,
                              boundaryMargin: const EdgeInsets.all(20),
                              minScale: 0.5,
                              maxScale: 4,
                              child: Image.network(photoUrl, fit: BoxFit.contain),
                            ),
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
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
                            child: const CircularProgressIndicator(color: Colors.orange),
                          );
                        },
                      ),
                    ),
                  ),
                ],

                if (data['volunteerName'] != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.directions_run_outlined, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        "${context.translate('volunteers')}: ${data['volunteerName']}",
                        style: TextStyle(color: textSecondary, fontSize: 12.5),
                      ),
                    ],
                  ),
                ],
                if (isActiveTab) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (status == 'Pending') ...[
                        OutlinedButton.icon(
                          onPressed: () => _rejectDonation(context, dId),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.redAccent),
                          label: Text(context.translate('reject'), style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _acceptDonation(context, dId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                          label: Text(context.translate('accept'), style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ] else if (status == 'Accepted by NGO' || status == 'Accepted') ...[
                        ElevatedButton.icon(
                          onPressed: () => _showAssignVolunteerSheet(context, dId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade800,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          icon: const Icon(Icons.assignment_ind_outlined, size: 16, color: Colors.white),
                          label: Text(context.translate('assign_volunteer'), style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ] else if (status == 'Delivered') ...[
                        ElevatedButton.icon(
                          onPressed: () => _distributeClothes(context, dId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          icon: const Icon(Icons.volunteer_activism_outlined, size: 16, color: Colors.white),
                          label: Text(context.translate('distribute_to_needy'), style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ] else ...[
                        Text(
                          status == 'Assigned to Volunteer'
                              ? "Awaiting volunteer acceptance..."
                              : status == 'Accepted by Volunteer'
                                  ? "Volunteer accepted. Awaiting pickup..."
                                  : "Garments are in transit...",
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: textSecondary),
                        )
                      ]
                    ],
                  )
                ] else ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(context.translate('delete_record')),
                              content: Text(context.translate('delete_confirm')),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(context.translate('cancel')),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('donations')
                                          .doc(dId)
                                          .delete();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Record deleted successfully.")),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Error deleting: $e"), backgroundColor: Colors.red),
                                        );
                                      }
                                    }
                                  },
                                  child: Text(
                                    context.translate('delete'),
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white),
                        label: Text(
                          context.translate('delete_record'),
                          style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ]
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
      case "Pending":
        bg = Colors.orange.shade50;
        text = Colors.orange.shade800;
        break;
      case "Accepted by NGO":
      case "Accepted":
        bg = Colors.blue.shade50;
        text = Colors.blue.shade800;
        break;
      case "Assigned to Volunteer":
        bg = Colors.indigo.shade50;
        text = Colors.indigo.shade800;
        break;
      case "Accepted by Volunteer":
        bg = Colors.purple.shade50;
        text = Colors.purple.shade800;
        break;
      case "Picked Up":
        bg = Colors.pink.shade50;
        text = Colors.pink.shade800;
        break;
      case "Delivered":
        bg = Colors.green.shade50;
        text = Colors.green.shade800;
        break;
      case "Distributed":
        bg = Colors.teal.shade50;
        text = Colors.teal.shade800;
        break;
      case "Rejected":
        bg = Colors.red.shade50;
        text = Colors.red.shade800;
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