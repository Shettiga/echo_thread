import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echo_thread/services/theme_service.dart';
import 'package:echo_thread/widgets/navigation_drawer.dart';
import 'package:echo_thread/screens/login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentTabIndex = 0;
  String _adminName = "Admin";
  String _adminEmail = "";
  String? _adminPhoto;

  @override
  void initState() {
    super.initState();
    _loadAdminProfile();
  }

  Future<void> _loadAdminProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (mounted) {
            setState(() {
              _adminName = data['name'] ?? "Administrator";
              _adminEmail = data['email'] ?? user.email ?? "";
              _adminPhoto = data['profileImage'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint("[ADMIN_DASHBOARD] Error loading admin profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();
    final isDark = themeService.isDark(context);
    final themeColor = const Color(0xFF673AB7); // Admin Purple Theme Color

    final List<Widget> panels = [
      _OverviewPanel(themeColor: themeColor),
      _UserManagementPanel(themeColor: themeColor),
      _NgoManagementPanel(themeColor: themeColor),
      _DonationManagementPanel(themeColor: themeColor),
      _VolunteerManagementPanel(themeColor: themeColor),
      _FeedbackPanel(themeColor: themeColor),
      _SupportPanel(themeColor: themeColor),
      _NotificationPanel(themeColor: themeColor),
      _ReportsPanel(themeColor: themeColor),
      _AdminProfilePanel(
        themeColor: themeColor,
        adminName: _adminName,
        adminEmail: _adminEmail,
        adminPhoto: _adminPhoto,
        onProfileUpdated: _loadAdminProfile,
      ),
    ];

    final List<String> panelTitles = [
      "Admin Console Overview",
      "User Accounts Directory",
      "NGO Verifications",
      "Donation Pipeline",
      "Volunteer Management",
      "User Feedback Feed",
      "Support Tickets Console",
      "Broadcast Center",
      "System Analytics Reports",
      "Admin Credentials Profile",
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 1000;

        return Scaffold(
          key: _scaffoldKey,
          drawer: const AppNavigationDrawer(currentRoute: 'dashboard'),
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FC),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            elevation: 1,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.shield_outlined, color: themeColor),
                ),
                const SizedBox(width: 12),
                Text(
                  panelTitles[_currentTabIndex],
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Row(
            children: [
              if (isDesktop)
                NavigationRail(
                  selectedIndex: _currentTabIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _currentTabIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  selectedLabelTextStyle: TextStyle(
                    color: themeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  unselectedLabelTextStyle: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                  backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  selectedIconTheme: IconThemeData(color: themeColor),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text("Overview"),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people),
                      label: Text("Users"),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.home_work_outlined),
                      selectedIcon: Icon(Icons.home_work),
                      label: Text("NGOs"),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.volunteer_activism_outlined),
                      selectedIcon: Icon(Icons.volunteer_activism),
                      label: Text("Donations"),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.directions_run_outlined),
                      selectedIcon: Icon(Icons.directions_run),
                      label: Text("Volunteers"),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.feedback_outlined),
                      selectedIcon: Icon(Icons.feedback),
                      label: Text("Feedback"),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.support_agent),
                      selectedIcon: Icon(Icons.support_agent),
                      label: Text("Tickets"),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.campaign_outlined),
                      selectedIcon: Icon(Icons.campaign),
                      label: Text("Broadcast"),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.analytics_outlined),
                      selectedIcon: Icon(Icons.analytics),
                      label: Text("Reports"),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: Text("Profile"),
                    ),
                  ],
                ),
              Expanded(
                child: panels[_currentTabIndex],
              ),
            ],
          ),
          bottomNavigationBar: isDesktop
              ? null
              : BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  currentIndex: _currentTabIndex > 4 ? 4 : _currentTabIndex,
                  selectedItemColor: themeColor,
                  unselectedItemColor: Colors.grey,
                  backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  onTap: (index) {
                    if (index == 4) {
                      _showMoreOptionsBottomSheet(context);
                    } else {
                      setState(() {
                        _currentTabIndex = index;
                      });
                    }
                  },
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.dashboard_outlined),
                      label: "Stats",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.people_outlined),
                      label: "Users",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_work_outlined),
                      label: "NGOs",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.volunteer_activism_outlined),
                      label: "Donations",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.more_horiz),
                      label: "More",
                    ),
                  ],
                ),
        );
      },
    );
  }

  void _showMoreOptionsBottomSheet(BuildContext context) {
    final isDark = ThemeService().isDark(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "System Management Options",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildMoreItem(context, Icons.directions_run, "Volunteers", 4),
                  _buildMoreItem(context, Icons.feedback, "Feedback", 5),
                  _buildMoreItem(context, Icons.support_agent, "Tickets", 6),
                  _buildMoreItem(context, Icons.campaign, "Broadcast", 7),
                  _buildMoreItem(context, Icons.analytics, "Reports", 8),
                  _buildMoreItem(context, Icons.person, "Profile", 9),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoreItem(
      BuildContext context, IconData icon, String label, int targetIndex) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        setState(() {
          _currentTabIndex = targetIndex;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF673AB7).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF673AB7)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          )
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// OVERVIEW PANEL (STATS & CUSTOM CHARTS)
// ----------------------------------------------------
class _OverviewPanel extends StatelessWidget {
  final Color themeColor;
  const _OverviewPanel({required this.themeColor});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService().isDark(context);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('donations').snapshots(),
          builder: (context, donationSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting ||
                donationSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
            }

            final userDocs = userSnapshot.data?.docs ?? [];
            final donationDocs = donationSnapshot.data?.docs ?? [];

            // Aggregate counts
            int totalUsers = userDocs.length;
            int totalDonors = userDocs.where((d) {
              final r = (d.data() as Map<String, dynamic>)['role']?.toString().toLowerCase();
              return r == 'donor';
            }).length;
            int totalVolunteers = userDocs.where((d) {
              final r = (d.data() as Map<String, dynamic>)['role']?.toString().toLowerCase();
              return r == 'volunteer';
            }).length;
            int totalNGOs = userDocs.where((d) {
              final r = (d.data() as Map<String, dynamic>)['role']?.toString().toLowerCase();
              return r == 'ngo';
            }).length;

            int totalDonations = donationDocs.length;
            int completedDonations = donationDocs.where((d) {
              final s = (d.data() as Map<String, dynamic>)['status']?.toString().toLowerCase();
              return s == 'completed' || s == 'delivered' || s == 'distributed';
            }).length;
            int pendingDonations = donationDocs.where((d) {
              final s = (d.data() as Map<String, dynamic>)['status']?.toString().toLowerCase();
              return s == 'pending';
            }).length;

            // Simple active user approximation: users registered in the last 7 days or those with role admin
            int activeUsers = userDocs.where((d) {
              final data = d.data() as Map<String, dynamic>;
              final date = (data['createdAt'] as Timestamp?)?.toDate();
              if (date == null) return true;
              return DateTime.now().difference(date).inDays <= 7;
            }).length;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Grid
                  LayoutBuilder(
                    builder: (context, boxConstraints) {
                      int crossAxisCount = boxConstraints.maxWidth > 800 ? 4 : 2;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.4,
                        children: [
                          _buildKpiCard(context, "Total Accounts", totalUsers.toString(),
                              Icons.people, Colors.blue),
                          _buildKpiCard(context, "NGOs Registered", totalNGOs.toString(),
                              Icons.home_work, Colors.orange),
                          _buildKpiCard(context, "Active Volunteers", totalVolunteers.toString(),
                              Icons.directions_run, Colors.indigo),
                          _buildKpiCard(context, "Donors Database", totalDonors.toString(),
                              Icons.volunteer_activism, Colors.teal),
                          _buildKpiCard(context, "Total Pipeline", totalDonations.toString(),
                              Icons.all_inbox, Colors.purple),
                          _buildKpiCard(context, "Pending Actions", pendingDonations.toString(),
                              Icons.pending_actions, Colors.amber),
                          _buildKpiCard(context, "Completed Handshakes", completedDonations.toString(),
                              Icons.task_alt, Colors.green),
                          _buildKpiCard(context, "Active Session (7d)", activeUsers.toString(),
                              Icons.bolt, Colors.red),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // Analytics Section with Charts & Progress Indicators
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            // Custom User distribution bar chart
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "User Distribution Breakdown",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 24),
                                  _buildUserBarChart(context, totalDonors, totalVolunteers, totalNGOs),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Pipeline Health Indicator",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 24),
                              _buildDonationCircularHealth(context, totalDonations, completedDonations, pendingDonations),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildKpiCard(BuildContext context, String title, String val, IconData icon, Color color) {
    final isDark = ThemeService().isDark(context);
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                val,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildUserBarChart(BuildContext context, int donors, int volunteers, int ngos) {
    int maxVal = [donors, volunteers, ngos].reduce((curr, next) => curr > next ? curr : next);
    if (maxVal == 0) maxVal = 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildBar(context, "Donors", donors, maxVal, Colors.teal),
        _buildBar(context, "Volunteers", volunteers, maxVal, Colors.indigo),
        _buildBar(context, "NGOs", ngos, maxVal, Colors.orange),
      ],
    );
  }

  Widget _buildBar(BuildContext context, String label, int val, int maxVal, Color color) {
    double percent = val / maxVal;
    double barHeight = percent * 160;
    if (barHeight < 10) barHeight = 10; // Minimum bar height to show something

    final isDark = ThemeService().isDark(context);

    return Column(
      children: [
        Text(
          val.toString(),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 700),
          width: 32,
          height: barHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.65)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        )
      ],
    );
  }

  Widget _buildDonationCircularHealth(
      BuildContext context, int total, int completed, int pending) {
    double completedPct = total == 0 ? 0 : completed / total;
    double pendingPct = total == 0 ? 0 : pending / total;
    double otherPct = 1.0 - completedPct - pendingPct;
    if (otherPct < 0) otherPct = 0;

    final isDark = ThemeService().isDark(context);
    final textStyle = TextStyle(
      fontSize: 13,
      color: isDark ? Colors.white70 : Colors.black54,
      fontWeight: FontWeight.w500,
    );

    return Column(
      children: [
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: CircularProgressIndicator(
                  value: completedPct,
                  strokeWidth: 10,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${(completedPct * 100).toStringAsFixed(0)}%",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const Text("Fulfilled", style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildLegendRow("Completed Actions", completed, Colors.green, textStyle),
        const SizedBox(height: 8),
        _buildLegendRow("Pending Requests", pending, Colors.amber, textStyle),
        const SizedBox(height: 8),
        _buildLegendRow("In-Progress Pipes", (total - completed - pending), Colors.purple, textStyle),
      ],
    );
  }

  Widget _buildLegendRow(String title, int count, Color color, TextStyle style) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 8),
            Text(title, style: style),
          ],
        ),
        Text(count.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ----------------------------------------------------
// USER MANAGEMENT PANEL
// ----------------------------------------------------
class _UserManagementPanel extends StatefulWidget {
  final Color themeColor;
  const _UserManagementPanel({required this.themeColor});

  @override
  State<_UserManagementPanel> createState() => _UserManagementPanelState();
}

class _UserManagementPanelState extends State<_UserManagementPanel> {
  String _searchQuery = "";
  String _roleFilter = "All";

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService().isDark(context);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Filter Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: "Search user database by name or email...",
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _roleFilter,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: "All", child: Text("All Roles")),
                  DropdownMenuItem(value: "Donor", child: Text("Donors")),
                  DropdownMenuItem(value: "Volunteer", child: Text("Volunteers")),
                  DropdownMenuItem(value: "NGO", child: Text("NGOs")),
                  DropdownMenuItem(value: "Admin", child: Text("Admins")),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _roleFilter = val;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // User table listing
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No users in system."));
                }

                // Filter logic
                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? "").toString().toLowerCase();
                  final email = (data['email'] ?? "").toString().toLowerCase();
                  final role = (data['role'] ?? "").toString();

                  bool matchesSearch = name.contains(_searchQuery) || email.contains(_searchQuery);
                  bool matchesRole = _roleFilter == "All" || role.toLowerCase() == _roleFilter.toLowerCase();

                  return matchesSearch && matchesRole;
                }).toList();

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final uData = doc.data() as Map<String, dynamic>;
                    final uId = doc.id;
                    final String name = uData['name'] ?? "No Name";
                    final String phone = uData['phone'] ?? "No Phone";
                    final String email = uData['email'] ?? "No Email";
                    final String role = uData['role'] ?? "Donor";
                    final String status = uData['status'] ?? "Active";
                    final Timestamp? regTimestamp = uData['createdAt'] as Timestamp?;
                    final String dateStr = regTimestamp != null
                        ? "${regTimestamp.toDate().day}/${regTimestamp.toDate().month}/${regTimestamp.toDate().year}"
                        : "N/A";

                    return Card(
                      color: cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        ),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: widget.themeColor.withOpacity(0.1),
                          child: Icon(Icons.person, color: widget.themeColor),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("$email • $phone\nRole: $role • Registered: $dateStr"),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: status.toLowerCase() == 'active'
                                    ? Colors.green.withOpacity(0.12)
                                    : Colors.red.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: status.toLowerCase() == 'active' ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_note, color: Colors.blue),
                              onPressed: () => _showEditUserDialog(context, uId, name, phone, role, status),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, String uid, String name, String phone, String role, String status) {
    final nameCtrl = TextEditingController(text: name);
    final phoneCtrl = TextEditingController(text: phone);
    String selectedRole = role;
    String selectedStatus = status;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Edit User Account"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Full Name")),
                  const SizedBox(height: 10),
                  TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Phone Number")),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: "Role"),
                    items: const [
                      DropdownMenuItem(value: "Donor", child: Text("Donor")),
                      DropdownMenuItem(value: "Volunteer", child: Text("Volunteer")),
                      DropdownMenuItem(value: "NGO", child: Text("NGO")),
                      DropdownMenuItem(value: "Admin", child: Text("Admin")),
                    ],
                    onChanged: (val) => setDialogState(() => selectedRole = val!),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(labelText: "Status"),
                    items: const [
                      DropdownMenuItem(value: "Active", child: Text("Active")),
                      DropdownMenuItem(value: "Deactivated", child: Text("Deactivated")),
                    ],
                    onChanged: (val) => setDialogState(() => selectedStatus = val!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    // Delete account completely
                    Navigator.pop(context);
                    _confirmDeleteUser(context, uid, name);
                  },
                  child: const Text("Delete User", style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: widget.themeColor),
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('users').doc(uid).update({
                      'name': nameCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'role': selectedRole,
                      'status': selectedStatus,
                    });
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("Save", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteUser(BuildContext context, String uid, String name) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Account Deletion"),
          content: Text("Are you absolutely sure you want to delete the account for '$name'? This action is permanent and cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(uid).delete();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Delete Account", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

// ----------------------------------------------------
// NGO VERIFICATION PANEL
// ----------------------------------------------------
class _NgoManagementPanel extends StatelessWidget {
  final Color themeColor;
  const _NgoManagementPanel({required this.themeColor});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService().isDark(context);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'NGO')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No NGO accounts registered."));
          }

          final ngoDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: ngoDocs.length,
            itemBuilder: (context, index) {
              final doc = ngoDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final uid = doc.id;
              final String name = data['name'] ?? "No Name";
              final String email = data['email'] ?? "No Email";
              final String phone = data['phone'] ?? "No Phone";
              final String status = data['status'] ?? "Pending";

              return Card(
                color: cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          _buildStatusChip(status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("Email: $email"),
                      Text("Contact: $phone"),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (status.toLowerCase() != 'approved')
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: () => _updateNgoStatus(uid, "Approved"),
                              icon: const Icon(Icons.check, color: Colors.white),
                              label: const Text("Approve NGO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          const SizedBox(width: 8),
                          if (status.toLowerCase() != 'rejected')
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                              onPressed: () => _updateNgoStatus(uid, "Rejected"),
                              icon: const Icon(Icons.close, color: Colors.red),
                              label: const Text("Reject", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ),
                          const SizedBox(width: 8),
                          if (status.toLowerCase() == 'approved' || status.toLowerCase() == 'rejected')
                            TextButton(
                              onPressed: () => _updateNgoStatus(uid, "Pending"),
                              child: const Text("Move to Pending"),
                            ),
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
    );
  }

  Future<void> _updateNgoStatus(String uid, String status) async {
    // 1. Update user profile
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'status': status,
    });
    // 2. Log verification
    await FirebaseFirestore.instance.collection('ngo_verifications').doc(uid).set({
      'ngoId': uid,
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.orange;
    if (status.toLowerCase() == 'approved') {
      color = Colors.green;
    } else if (status.toLowerCase() == 'rejected') {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}

// ----------------------------------------------------
// DONATION PIPELINE PANEL
// ----------------------------------------------------
class _DonationManagementPanel extends StatefulWidget {
  final Color themeColor;
  const _DonationManagementPanel({required this.themeColor});

  @override
  State<_DonationManagementPanel> createState() => _DonationManagementPanelState();
}

class _DonationManagementPanelState extends State<_DonationManagementPanel> {
  String _searchQuery = "";
  String _statusFilter = "All";

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService().isDark(context);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: "Search donations by clothes type or donor name...",
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _statusFilter,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: "All", child: Text("All Statuses")),
                  DropdownMenuItem(value: "Pending", child: Text("Pending")),
                  DropdownMenuItem(value: "Accepted", child: Text("Accepted")),
                  DropdownMenuItem(value: "In Progress", child: Text("In Progress")),
                  DropdownMenuItem(value: "Delivered", child: Text("Delivered")),
                  DropdownMenuItem(value: "Completed", child: Text("Completed")),
                  DropdownMenuItem(value: "Cancelled", child: Text("Cancelled")),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _statusFilter = val;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('donations').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No donations pipeline reports."));
                }

                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final clothes = (data['clothes'] ?? "").toString().toLowerCase();
                  final donor = (data['donorName'] ?? "").toString().toLowerCase();
                  final status = (data['status'] ?? "").toString().toLowerCase();

                  bool matchesSearch = clothes.contains(_searchQuery) || donor.contains(_searchQuery);
                  bool matchesStatus = _statusFilter == "All" || status == _statusFilter.toLowerCase();

                  return matchesSearch && matchesStatus;
                }).toList();

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final dData = doc.data() as Map<String, dynamic>;
                    final String dId = doc.id;
                    final String clothes = dData['clothes'] ?? "Clothes";
                    final int qty = int.tryParse(dData['quantity']?.toString() ?? '1') ?? 1;
                    final String donorName = dData['donorName'] ?? "Anonymous";
                    final String ngoName = dData['ngoName'] ?? "Unassigned NGO";
                    final String volunteerName = dData['volunteerName'] ?? "Unassigned Volunteer";
                    final String status = dData['status'] ?? "Pending";
                    final Timestamp? created = dData['createdAt'] as Timestamp?;
                    final String dateStr = created != null
                        ? "${created.toDate().day}/${created.toDate().month}/${created.toDate().year}"
                        : "N/A";

                    return Card(
                      color: cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        ),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.withOpacity(0.1),
                          child: const Icon(Icons.checkroom, color: Colors.green),
                        ),
                        title: Text("$clothes (Qty: $qty)", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Donor: $donorName • NGO: $ngoName\nVolunteer: $volunteerName • Date: $dateStr"),
                        isThreeLine: true,
                        trailing: DropdownButton<String>(
                          value: _formatStatusValue(status),
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
                          onChanged: (val) async {
                            if (val != null) {
                              await FirebaseFirestore.instance
                                  .collection('donations')
                                  .doc(dId)
                                  .update({'status': val});
                            }
                          },
                          items: const [
                            DropdownMenuItem(value: "Pending", child: Text("Pending")),
                            DropdownMenuItem(value: "Accepted", child: Text("Accepted")),
                            DropdownMenuItem(value: "In Progress", child: Text("In Progress")),
                            DropdownMenuItem(value: "Delivered", child: Text("Delivered")),
                            DropdownMenuItem(value: "Completed", child: Text("Completed")),
                            DropdownMenuItem(value: "Cancelled", child: Text("Cancelled")),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  String _formatStatusValue(String firestoreValue) {
    final lower = firestoreValue.toLowerCase();
    if (lower.contains('pending')) return 'Pending';
    if (lower.contains('accepted')) return 'Accepted';
    if (lower.contains('progress') || lower.contains('transit') || lower.contains('picked')) return 'In Progress';
    if (lower.contains('delivered')) return 'Delivered';
    if (lower.contains('completed') || lower.contains('distributed')) return 'Completed';
    if (lower.contains('cancelled') || lower.contains('rejected')) return 'Cancelled';
    return 'Pending';
  }
}

// ----------------------------------------------------
// VOLUNTEER PANEL
// ----------------------------------------------------
class _VolunteerManagementPanel extends StatelessWidget {
  final Color themeColor;
  const _VolunteerManagementPanel({required this.themeColor});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService().isDark(context);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'Volunteer')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No volunteer profiles registered."));
          }

          final volunteers = snapshot.data!.docs;

          return ListView.builder(
            itemCount: volunteers.length,
            itemBuilder: (context, index) {
              final vDoc = volunteers[index];
              final data = vDoc.data() as Map<String, dynamic>;
              final String vid = vDoc.id;
              final String name = data['name'] ?? "Volunteer";
              final String phone = data['phone'] ?? "No Contact";
              final String status = data['status'] ?? "Active";

              // Compute simple metrics using StreamBuilder aggregates
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('donations')
                    .where('volunteerId', isEqualTo: vid)
                    .snapshots(),
                builder: (context, dSnapshot) {
                  int totalAssigned = 0;
                  int completedTasks = 0;

                  if (dSnapshot.hasData) {
                    final docs = dSnapshot.data!.docs;
                    totalAssigned = docs.length;
                    completedTasks = docs.where((doc) {
                      final s = (doc.data() as Map<String, dynamic>)['status']?.toString().toLowerCase();
                      return s == 'completed' || s == 'delivered' || s == 'distributed';
                    }).length;
                  }

                  return Card(
                    color: cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      ),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo.withOpacity(0.1),
                        child: const Icon(Icons.directions_run, color: Colors.indigo),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Phone: $phone\nTasks Assigned: $totalAssigned | Completed: $completedTasks"),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: status.toLowerCase() == 'active'
                                  ? Colors.green.withOpacity(0.12)
                                  : Colors.red.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: status.toLowerCase() == 'active' ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            underline: const SizedBox(),
                            icon: const Icon(Icons.more_vert),
                            onChanged: (val) async {
                              if (val == 'Suspend') {
                                await FirebaseFirestore.instance.collection('users').doc(vid).update({'status': 'Suspended'});
                              } else if (val == 'Activate') {
                                await FirebaseFirestore.instance.collection('users').doc(vid).update({'status': 'Active'});
                              } else if (val == 'Assign') {
                                _showForceAssignDonationDialog(context, vid, name);
                              }
                            },
                            items: [
                              DropdownMenuItem(value: status.toLowerCase() == 'suspended' ? 'Activate' : 'Suspend', child: Text(status.toLowerCase() == 'suspended' ? 'Activate' : 'Suspend')),
                              const DropdownMenuItem(value: 'Assign', child: Text('Assign Task')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showForceAssignDonationDialog(BuildContext context, String vid, String vName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Assign Task to $vName"),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('donations')
                  .where('status', isEqualTo: 'Accepted by NGO')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text("No pending NGO accepted donations to assign.");
                }

                final unassignedDocs = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: unassignedDocs.length,
                  itemBuilder: (context, index) {
                    final doc = unassignedDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final did = doc.id;
                    final String clothes = data['clothes'] ?? "Clothes";
                    final int qty = int.tryParse(data['quantity']?.toString() ?? '1') ?? 1;

                    return Card(
                      child: ListTile(
                        title: Text("$clothes (Qty: $qty)"),
                        subtitle: Text("Donor: ${data['donorName'] ?? "Anonymous"}"),
                        trailing: const Icon(Icons.add, color: Colors.green),
                        onTap: () async {
                          await FirebaseFirestore.instance.collection('donations').doc(did).update({
                            'status': 'Assigned to Volunteer',
                            'volunteerId': vid,
                            'volunteerName': vName,
                            'assignedAt': FieldValue.serverTimestamp(),
                          });
                          await FirebaseFirestore.instance.collection('volunteer_assignments').add({
                            'donationId': did,
                            'volunteerId': vid,
                            'volunteerName': vName,
                            'assignedAt': FieldValue.serverTimestamp(),
                          });
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            )
          ],
        );
      },
    );
  }
}

// ----------------------------------------------------
// USER FEEDBACK PANEL
// ----------------------------------------------------
class _FeedbackPanel extends StatelessWidget {
  final Color themeColor;
  const _FeedbackPanel({required this.themeColor});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService().isDark(context);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('feedbacks').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No feedback reports found."));
          }

          final feedbacks = snapshot.data!.docs;

          return ListView.builder(
            itemCount: feedbacks.length,
            itemBuilder: (context, index) {
              final doc = feedbacks[index];
              final data = doc.data() as Map<String, dynamic>;
              final String id = doc.id;
              final String email = data['userEmail'] ?? "Anonymous";
              final String subject = data['subject'] ?? "General Feedback";
              final String msg = data['message'] ?? "No message contents.";
              final double rating = double.tryParse(data['rating']?.toString() ?? '5') ?? 5.0;
              final String reply = data['reply'] ?? "";

              return Card(
                color: cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                          Text("${rating.toInt()} ⭐", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text("From: $email", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text(msg),
                      if (reply.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text("Admin Response: $reply", style: const TextStyle(fontStyle: FontStyle.italic)),
                        )
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: themeColor),
                            onPressed: () => _showFeedbackReplyDialog(context, id, reply),
                            icon: const Icon(Icons.reply, color: Colors.white),
                            label: const Text("Reply", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    );
  }

  void _showFeedbackReplyDialog(BuildContext context, String fid, String existingReply) {
    final replyCtrl = TextEditingController(text: existingReply);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reply to Feedback"),
          content: TextField(
            controller: replyCtrl,
            maxLines: 4,
            decoration: const InputDecoration(labelText: "Your response message..."),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: themeColor),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('feedbacks').doc(fid).update({
                  'reply': replyCtrl.text.trim(),
                  'status': 'Resolved',
                });
                // Also write to feedback collection
                await FirebaseFirestore.instance.collection('feedback').doc(fid).set({
                  'feedbackId': fid,
                  'reply': replyCtrl.text.trim(),
                  'status': 'Resolved',
                }, SetOptions(merge: true));
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Submit", style: TextStyle(color: Colors.white)),
            )
          ],
        );
      },
    );
  }
}

// ----------------------------------------------------
// SUPPORT TICKETS PANEL
// ----------------------------------------------------
class _SupportPanel extends StatelessWidget {
  final Color themeColor;
  const _SupportPanel({required this.themeColor});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService().isDark(context);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('support_requests').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No support tickets registered."));
          }

          final tickets = snapshot.data!.docs;

          return ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final doc = tickets[index];
              final data = doc.data() as Map<String, dynamic>;
              final String id = doc.id;
              final String email = data['userEmail'] ?? "Anonymous";
              final String subject = data['subject'] ?? "System Issue";
              final String desc = data['description'] ?? "No description.";
              final String status = data['status'] ?? "Open";
              final String response = data['response'] ?? "";

              return Card(
                color: cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: status.toLowerCase() == 'open'
                                  ? Colors.red.withOpacity(0.12)
                                  : Colors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: status.toLowerCase() == 'open' ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text("From: $email", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text(desc),
                      if (response.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text("Staff Reply: $response", style: const TextStyle(fontStyle: FontStyle.italic)),
                        )
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (status.toLowerCase() == 'open')
                            TextButton(
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection('support_requests').doc(id).update({'status': 'Closed'});
                                await FirebaseFirestore.instance.collection('support_tickets').doc(id).set({'status': 'Closed'}, SetOptions(merge: true));
                              },
                              child: const Text("Close Ticket", style: TextStyle(color: Colors.red)),
                            ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: themeColor),
                            onPressed: () => _showSupportResponseDialog(context, id, response),
                            icon: const Icon(Icons.edit_note, color: Colors.white),
                            label: const Text("Respond", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    );
  }

  void _showSupportResponseDialog(BuildContext context, String id, String existingResponse) {
    final responseCtrl = TextEditingController(text: existingResponse);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Respond to Issue Ticket"),
          content: TextField(
            controller: responseCtrl,
            maxLines: 4,
            decoration: const InputDecoration(labelText: "Your official response..."),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: themeColor),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('support_requests').doc(id).update({
                  'response': responseCtrl.text.trim(),
                  'status': 'Resolved',
                });
                await FirebaseFirestore.instance.collection('support_tickets').doc(id).set({
                  'ticketId': id,
                  'response': responseCtrl.text.trim(),
                  'status': 'Resolved',
                }, SetOptions(merge: true));
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Submit Response", style: TextStyle(color: Colors.white)),
            )
          ],
        );
      },
    );
  }
}

// ----------------------------------------------------
// NOTIFICATION BROADCAST CENTER
// ----------------------------------------------------
class _NotificationPanel extends StatefulWidget {
  final Color themeColor;
  const _NotificationPanel({required this.themeColor});

  @override
  State<_NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<_NotificationPanel> {
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _targetRole = "All Users";
  bool _isSending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService().isDark(context);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Send Push / App Announcement", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: "Announcement Title"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _msgCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: "Announcement Details / Description"),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _targetRole,
                    decoration: const InputDecoration(labelText: "Target Audience"),
                    items: const [
                      DropdownMenuItem(value: "All Users", child: Text("All Registered Users")),
                      DropdownMenuItem(value: "Donor", child: Text("Donors Only")),
                      DropdownMenuItem(value: "Volunteer", child: Text("Volunteers Only")),
                      DropdownMenuItem(value: "NGO", child: Text("NGOs Only")),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _targetRole = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: widget.themeColor),
                      onPressed: _isSending ? null : _broadcastAlert,
                      child: _isSending
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Broadcast Message Alert", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _broadcastAlert() async {
    final title = _titleCtrl.text.trim();
    final message = _msgCtrl.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title and message are required."), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': title,
        'message': message,
        'target': _targetRole,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _titleCtrl.clear();
      _msgCtrl.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Announcement Broadcasted Successfully! 📢"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Broadcasting failed: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
}

// ----------------------------------------------------
// SYSTEM REPORTS & EXPORT PANEL
// ----------------------------------------------------
class _ReportsPanel extends StatefulWidget {
  final Color themeColor;
  const _ReportsPanel({required this.themeColor});

  @override
  State<_ReportsPanel> createState() => _ReportsPanelState();
}

class _ReportsPanelState extends State<_ReportsPanel> {
  String _timeFilter = "Monthly";

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService().isDark(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Operational System Reports", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: _timeFilter,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: "Daily", child: Text("Daily Report")),
                  DropdownMenuItem(value: "Weekly", child: Text("Weekly Report")),
                  DropdownMenuItem(value: "Monthly", child: Text("Monthly Report")),
                  DropdownMenuItem(value: "Yearly", child: Text("Yearly Report")),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _timeFilter = val;
                    });
                  }
                },
              )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 800 ? 2 : 1,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 1.6,
              children: [
                _buildReportExportCard("User Account Demographics", "Active registration summaries categorized by roles.", Icons.people_outline, Colors.blue),
                _buildReportExportCard("Donation Throughput", "Performance indicators on donation pick-up and drop-off timelines.", Icons.volunteer_activism_outlined, Colors.green),
                _buildReportExportCard("NGO Capacity Analytics", "Detailed performance audits on NGO distributions.", Icons.home_work_outlined, Colors.orange),
                _buildReportExportCard("Volunteer Deployment Logs", "Efficiency stats and pickup response times of volunteers.", Icons.directions_run_outlined, Colors.indigo),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildReportExportCard(String title, String desc, IconData icon, Color accentColor) {
    final isDark = ThemeService().isDark(context);
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                  onPressed: () => _triggerExport(title, "PDF"),
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 16),
                  label: const Text("Export PDF", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                  onPressed: () => _triggerExport(title, "Excel"),
                  icon: const Icon(Icons.table_view_outlined, color: Colors.white, size: 16),
                  label: const Text("Export Excel", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _triggerExport(String reportName, String format) async {
    // We will generate the actual formatted file string and save it to the local system path.
    String contents = "";
    String extension = "";
    if (format == 'Excel') {
      extension = ".csv";
      contents = "Report,Format,Date,Timeframe\n$reportName,ExcelSpreadsheet,${DateTime.now().toIso8601String()},$_timeFilter\n";
    } else {
      extension = ".txt";
      contents = "========================================\n"
          "ECHO THREAD SYSTEM REPORT: $reportName\n"
          "========================================\n"
          "Generated at: ${DateTime.now()}\n"
          "Timeframe: $_timeFilter\n"
          "----------------------------------------\n"
          "System operations metrics: Normal status.\n";
    }

    try {
      // Create path on device workspace
      final directory = Directory("d:/echo_thread/reports");
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final filename = "${reportName.replaceAll(' ', '_')}_$_timeFilter$extension";
      final file = File("${directory.path}/$filename");
      await file.writeAsString(contents);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text("Report Exported!"),
                ],
              ),
              content: Text("Successfully generated and saved report:\n\nName: $filename\nFormat: $format\nLocation: d:/echo_thread/reports/"),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Export failed: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ----------------------------------------------------
// ADMIN PROFILE & SETTINGS
// ----------------------------------------------------
class _AdminProfilePanel extends StatelessWidget {
  final Color themeColor;
  final String adminName;
  final String adminEmail;
  final String? adminPhoto;
  final VoidCallback onProfileUpdated;

  const _AdminProfilePanel({
    required this.themeColor,
    required this.adminName,
    required this.adminEmail,
    required this.adminPhoto,
    required this.onProfileUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();
    final isDark = themeService.isDark(context);
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 54,
                  backgroundColor: themeColor.withOpacity(0.1),
                  backgroundImage: adminPhoto != null && adminPhoto!.isNotEmpty
                      ? NetworkImage(adminPhoto!)
                      : null,
                  child: adminPhoto == null || adminPhoto!.isEmpty
                      ? Icon(Icons.person, size: 54, color: themeColor)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  adminName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Text(
                  adminEmail,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "System Administrator",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF673AB7)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Settings Card
          Card(
            color: bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text("Theme Customizations"),
                  subtitle: const Text("Switch app theme dynamically"),
                  trailing: DropdownButton<ThemeMode>(
                    value: themeService.themeMode,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                      DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                    ],
                    onChanged: (mode) {
                      if (mode != null) {
                        themeService.setThemeMode(mode);
                      }
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text("Change Password"),
                  onTap: () => _showChangePasswordDialog(context),
                  trailing: const Icon(Icons.chevron_right),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("System Log Out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: () => _logout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final passwordCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Update Password"),
          content: TextField(
            controller: passwordCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: "New Password"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: themeColor),
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null && passwordCtrl.text.trim().length >= 6) {
                  await user.updatePassword(passwordCtrl.text.trim());
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Password updated successfully!"), backgroundColor: Colors.green),
                    );
                  }
                }
              },
              child: const Text("Update", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
