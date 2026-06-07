import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class NGODashboard extends StatefulWidget {
  const NGODashboard({super.key});

  @override
  State<NGODashboard> createState() => _NGODashboardState();
}

class _NGODashboardState extends State<NGODashboard>
    with SingleTickerProviderStateMixin {
  String userName = "Loading...";
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
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFFFE0B2),
                              child: Icon(Icons.person, color: Colors.orange),
                            ),
                            title: Text(vName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(vData['email'] ?? ""),
                            trailing: const Icon(Icons.chevron_right, color: Colors.orange),
                            onTap: () async {
                              // Assign volunteer in Firestore
                              await FirebaseFirestore.instance
                                  .collection('donations')
                                  .doc(donationId)
                                  .update({
                                'status': 'Assigned',
                                'volunteerId': vId,
                                'volunteerName': vName,
                                'assignedAt': FieldValue.serverTimestamp(),
                              });

                              if (!context.mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Assigned to $vName! 🚚"),
                                  backgroundColor: Colors.green,
                                ),
                              );
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
    await FirebaseFirestore.instance
        .collection('donations')
        .doc(donationId)
        .update({
      'status': 'Distributed',
      'distributedAt': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Clothes marked as Distributed to the Needy! 🎁"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFFE65100);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
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
                        "Manage clothing distribution portal",
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
                          child: Icon(Icons.home_work_outlined, color: Colors.orange),
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
                Tab(text: "Distributed History"),
              ],
            ),

            // 🔹 TAB VIEW LISTS
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('donations').snapshots(),
                builder: (context, snapshot) {
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
                      // Active Tab (Pending, Assigned, Picked Up, Delivered)
                      _buildDonationList(
                        allDonations.where((doc) {
                          final status = (doc.data() as Map<String, dynamic>)['status'];
                          return status != 'Distributed';
                        }).toList(),
                        isActiveTab: true,
                      ),
                      // Distributed Tab (Distributed)
                      _buildDonationList(
                        allDonations.where((doc) {
                          final status = (doc.data() as Map<String, dynamic>)['status'];
                          return status == 'Distributed';
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
              isActiveTab ? "No active donations to manage" : "No garments distributed yet",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

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

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.orange.withValues(alpha: 0.15), width: 1.2),
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    _buildStatusPill(status),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "Donor: $donor",
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 13.5),
                ),
                const SizedBox(height: 4),
                Text(
                  "Address: $location",
                  style: const TextStyle(color: Colors.black54, fontSize: 12.5),
                ),
                if (data['volunteerName'] != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.directions_run_outlined, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        "Volunteer: ${data['volunteerName']}",
                        style: const TextStyle(color: Colors.black54, fontSize: 12.5),
                      ),
                    ],
                  ),
                ],
                if (isActiveTab) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (status == 'Pending')
                        ElevatedButton.icon(
                          onPressed: () => _showAssignVolunteerSheet(context, dId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade800,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          icon: const Icon(Icons.assignment_ind_outlined, size: 16, color: Colors.white),
                          label: const Text("Assign Volunteer", style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                        )
                      else if (status == 'Delivered')
                        ElevatedButton.icon(
                          onPressed: () => _distributeClothes(context, dId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          icon: const Icon(Icons.volunteer_activism_outlined, size: 16, color: Colors.white),
                          label: const Text("Distribute to Needy", style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                        )
                      else
                        Text(
                          status == 'Assigned'
                              ? "Waiting for volunteer pickup..."
                              : "Garments are in transit...",
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black45),
                        )
                    ],
                  )
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
      case "Distributed":
        bg = Colors.teal.shade50;
        text = Colors.teal.shade800;
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