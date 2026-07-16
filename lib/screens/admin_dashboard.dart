import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echo_thread/config.dart';
import 'package:echo_thread/services/theme_service.dart';
import 'package:echo_thread/widgets/navigation_drawer.dart';
import 'package:echo_thread/screens/login_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';
import 'package:echo_thread/widgets/profile_image_dialog.dart';
import 'package:echo_thread/services/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';

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
  String? _selectedUserRoleFilter;
  String? _selectedDonationStatusFilter;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor = const Color(0xFF673AB7); // Admin Purple Theme Color

    final List<Widget> panels = [
      _OverviewPanel(
        themeColor: themeColor,
        onTapCard: (index, {userRole, donationStatus}) {
          setState(() {
            _currentTabIndex = index;
            _selectedUserRoleFilter = userRole;
            _selectedDonationStatusFilter = donationStatus;
          });
        },
      ),
      _UserManagementPanel(
        themeColor: themeColor,
        initialRoleFilter: _selectedUserRoleFilter,
      ),
      _NgoManagementPanel(themeColor: themeColor),
      _DonationManagementPanel(
        themeColor: themeColor,
        initialStatusFilter: _selectedDonationStatusFilter,
      ),
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
          drawer: isDesktop ? null : Drawer(
            child: _buildDrawerContent(context, isSidebar: false),
          ),
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F8FC),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            elevation: 1,
            leading: isDesktop ? null : IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
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
          ),
          body: Row(
            children: [
              if (isDesktop)
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
                  ),
                  child: _buildDrawerContent(context, isSidebar: true),
                ),
              Expanded(
                child: panels[_currentTabIndex],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerContent(BuildContext context, {required bool isSidebar}) {
    final themeService = ThemeService();
    final isDark = themeService.isDark(context);
    final themeColor = const Color(0xFF673AB7);
    final textOnSurface = Theme.of(context).colorScheme.onSurface;

    final List<Map<String, dynamic>> menuItems = [
      {'title': 'Overview', 'icon': Icons.dashboard_outlined, 'selectedIcon': Icons.dashboard},
      {'title': 'Users', 'icon': Icons.people_outline, 'selectedIcon': Icons.people},
      {'title': 'NGOs', 'icon': Icons.home_work_outlined, 'selectedIcon': Icons.home_work},
      {'title': 'Donations', 'icon': Icons.volunteer_activism_outlined, 'selectedIcon': Icons.volunteer_activism},
      {'title': 'Volunteers', 'icon': Icons.directions_run_outlined, 'selectedIcon': Icons.directions_run},
      {'title': 'Feedback', 'icon': Icons.feedback_outlined, 'selectedIcon': Icons.feedback},
      {'title': 'Tickets', 'icon': Icons.support_agent_outlined, 'selectedIcon': Icons.support_agent},
      {'title': 'Broadcast', 'icon': Icons.campaign_outlined, 'selectedIcon': Icons.campaign},
      {'title': 'Reports', 'icon': Icons.analytics_outlined, 'selectedIcon': Icons.analytics},
      {'title': 'Profile', 'icon': Icons.person_outline, 'selectedIcon': Icons.person},
    ];

    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF2E2E2E), const Color(0xFF1E1E1E)]
                    : [themeColor, themeColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    showProfileImageDialog(
                      context: context,
                      imageUrl: _adminPhoto,
                      userName: _adminName,
                      userRole: "Administrator",
                      fallbackIcon: Icons.shield,
                      themeColor: themeColor,
                      onProfileUpdated: _loadAdminProfile,
                    );
                  },
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: _adminPhoto != null && _adminPhoto!.isNotEmpty
                        ? NetworkImage(_adminPhoto!)
                        : null,
                    child: _adminPhoto == null || _adminPhoto!.isEmpty
                        ? const Icon(Icons.shield, color: Colors.white, size: 26)
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _adminName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "Administrator",
                        style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menu Options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                ...List.generate(menuItems.length, (index) {
                  final item = menuItems[index];
                  final isSelected = _currentTabIndex == index;
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      isSelected ? item['selectedIcon'] : item['icon'],
                      color: isSelected ? (isDark ? Colors.white : themeColor) : Colors.grey,
                    ),
                    title: Text(
                      item['title'],
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? (isDark ? Colors.white : themeColor)
                            : textOnSurface.withOpacity(0.8),
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor: isDark
                        ? Colors.white.withOpacity(0.08)
                        : themeColor.withOpacity(0.08),
                    onTap: () {
                      setState(() {
                        _currentTabIndex = index;
                      });
                      if (!isSidebar) {
                        Navigator.pop(context);
                      }
                    },
                  );
                }),
                const Divider(),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.settings_outlined, color: Colors.grey),
                  title: Text("Settings", style: TextStyle(color: textOnSurface.withOpacity(0.8))),
                  onTap: () {
                    if (!isSidebar) Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  },
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.info_outline, color: Colors.grey),
                  title: Text("About", style: TextStyle(color: textOnSurface.withOpacity(0.8))),
                  onTap: () {
                    if (!isSidebar) Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
                  },
                ),
                const Divider(),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  onTap: () {
                    if (!isSidebar) Navigator.pop(context);
                    _logout(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out of EchoThread?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text("Logout"),
          ),
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
  final Function(int index, {String? userRole, String? donationStatus}) onTapCard;

  const _OverviewPanel({
    required this.themeColor,
    required this.onTapCard,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                        childAspectRatio: boxConstraints.maxWidth > 800 ? 1.4 : 1.15,
                        children: [
                          _buildKpiCard(context, "Total Accounts", totalUsers.toString(),
                              Icons.people, Colors.blue, () => onTapCard(1)),
                          _buildKpiCard(context, "NGOs Registered", totalNGOs.toString(),
                              Icons.home_work, Colors.orange, () => onTapCard(2)),
                          _buildKpiCard(context, "Active Volunteers", totalVolunteers.toString(),
                              Icons.directions_run, Colors.indigo, () => onTapCard(4)),
                          _buildKpiCard(context, "Donors Database", totalDonors.toString(),
                              Icons.volunteer_activism, Colors.teal, () => onTapCard(1, userRole: "Donor")),
                          _buildKpiCard(context, "Total Pipeline", totalDonations.toString(),
                              Icons.all_inbox, Colors.purple, () => onTapCard(3)),
                          _buildKpiCard(context, "Pending Actions", pendingDonations.toString(),
                              Icons.pending_actions, Colors.amber, () => onTapCard(3, donationStatus: "Pending")),
                          _buildKpiCard(context, "Completed Handshakes", completedDonations.toString(),
                              Icons.task_alt, Colors.green, () => onTapCard(3, donationStatus: "Completed")),
                          _buildKpiCard(context, "Active Session (7d)", activeUsers.toString(),
                              Icons.bolt, Colors.red, () => onTapCard(1)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),

                  // Analytics Section with Charts & Progress Indicators (Responsive Layout)
                  LayoutBuilder(
                    builder: (context, chartsConstraints) {
                      final bool isWide = chartsConstraints.maxWidth > 800;

                      final userBreakdownCard = Container(
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
                      );

                      final healthIndicatorCard = Container(
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
                      );

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: userBreakdownCard),
                            const SizedBox(width: 16),
                            Expanded(flex: 2, child: healthIndicatorCard),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            userBreakdownCard,
                            const SizedBox(height: 16),
                            healthIndicatorCard,
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildKpiCard(BuildContext context, String title, String val, IconData icon, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
        ),
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
  final String? initialRoleFilter;
  const _UserManagementPanel({required this.themeColor, this.initialRoleFilter});

  @override
  State<_UserManagementPanel> createState() => _UserManagementPanelState();
}

class _UserManagementPanelState extends State<_UserManagementPanel> {
  String _searchQuery = "";
  late String _roleFilter;

  @override
  void initState() {
    super.initState();
    _roleFilter = widget.initialRoleFilter ?? "All";
  }

  @override
  void didUpdateWidget(_UserManagementPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRoleFilter != oldWidget.initialRoleFilter) {
      setState(() {
        _roleFilter = widget.initialRoleFilter ?? "All";
      });
    }
  }

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
  final String? initialStatusFilter;
  const _DonationManagementPanel({required this.themeColor, this.initialStatusFilter});

  @override
  State<_DonationManagementPanel> createState() => _DonationManagementPanelState();
}

class _DonationManagementPanelState extends State<_DonationManagementPanel> {
  String _searchQuery = "";
  late String _statusFilter;

  final List<String> _statuses = ["All", "Pending", "Accepted", "Assigned", "Picked Up", "Completed"];

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialStatusFilter ?? "All";
  }

  @override
  void didUpdateWidget(_DonationManagementPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStatusFilter != oldWidget.initialStatusFilter) {
      setState(() {
        _statusFilter = widget.initialStatusFilter ?? "All";
      });
    }
  }

  double _getPipelineProgress(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('pending')) return 0.2;
    if (lower.contains('accepted')) return 0.4;
    if (lower.contains('assigned')) return 0.6;
    if (lower.contains('picked')) return 0.8;
    if (lower.contains('completed') || lower.contains('delivered') || lower.contains('distributed')) return 1.0;
    return 0.1;
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onPressed) {
    return Expanded(
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationCard(
    BuildContext context,
    QueryDocumentSnapshot doc,
    Color cardBg,
    bool isDark,
    Color themeColor,
  ) {
    final dData = doc.data() as Map<String, dynamic>;
    final String dId = doc.id;
    final String clothes = dData['clothes'] ?? "Clothes";
    final int qty = int.tryParse(dData['quantity']?.toString() ?? '1') ?? 1;
    final String donorName = dData['donorName'] ?? "Anonymous";
    final String donorAddress = dData['donorAddress'] ?? "No Address";
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
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "$clothes (Qty: $qty)",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusBgColor(status),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: _getStatusTextColor(status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDetailRow("Donor:", donorName, Icons.person_outline),
                _buildDetailRow("Address:", donorAddress, Icons.location_on_outlined),
                _buildDetailRow("NGO Hub:", ngoName, Icons.home_work_outlined),
                _buildDetailRow("Volunteer:", volunteerName, Icons.directions_run_outlined),
                _buildDetailRow("Date:", dateStr, Icons.calendar_today_outlined),
                const SizedBox(height: 12),
                
                // Pipeline Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Pipeline Stage",
                          style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          "${(_getPipelineProgress(status) * 100).toInt()}%",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: status.toLowerCase().contains('completed') || status.toLowerCase().contains('delivered') || status.toLowerCase().contains('distributed')
                                ? Colors.green
                                : themeColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _getPipelineProgress(status),
                        backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          status.toLowerCase().contains('completed') || status.toLowerCase().contains('delivered') || status.toLowerCase().contains('distributed')
                              ? Colors.green
                              : themeColor,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                _buildActionButton(context, "Details", Icons.info_outline, themeColor, () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Donation Details"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Clothes Type: $clothes", style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("Quantity: $qty"),
                          Text("Donor: $donorName"),
                          Text("Donor Address: $donorAddress"),
                          Text("NGO Hub: $ngoName"),
                          Text("Volunteer Name: $volunteerName"),
                          Text("Current Status: $status"),
                          Text("Report Date: $dateStr"),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Close"),
                        ),
                      ],
                    ),
                  );
                }),
                _buildActionButton(context, "Assign", Icons.person_add_alt_1_outlined, Colors.indigo, () {
                  _showAssignVolunteerDialog(context, dId, clothes);
                }),
                _buildActionButton(context, "Status", Icons.edit_outlined, Colors.orange, () {
                  _showEditStatusDialog(context, dId, status);
                }),
                _buildActionButton(context, "Delete", Icons.delete_outline, Colors.red, () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Delete Donation"),
                      content: const Text("Are you sure you want to delete this donation from the system?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () async {
                            Navigator.pop(context);
                            await FirebaseFirestore.instance.collection('donations').doc(dId).delete();
                          },
                          child: const Text("Delete", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService().isDark(context);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final themeColor = widget.themeColor;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔎 Search bar
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              hintText: "Search by clothes type or donor name...",
              filled: true,
              fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val.toLowerCase();
              });
            },
          ),
          const SizedBox(height: 16),

          // 🏷️ Scrollable Status Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statuses.map((status) {
                final isSelected = _statusFilter == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _statusFilter = status;
                      });
                    },
                    selectedColor: themeColor.withOpacity(0.2),
                    checkmarkColor: themeColor,
                    labelStyle: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? themeColor : (isDark ? Colors.white70 : Colors.black87),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // 📦 Donation Pipeline List
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
                  bool matchesStatus = false;

                  if (_statusFilter == "All") {
                    matchesStatus = true;
                  } else if (_statusFilter == "Pending") {
                    matchesStatus = status.contains("pending");
                  } else if (_statusFilter == "Accepted") {
                    matchesStatus = status.contains("accepted");
                  } else if (_statusFilter == "Assigned") {
                    matchesStatus = status.contains("assigned");
                  } else if (_statusFilter == "Picked Up") {
                    matchesStatus = status.contains("picked");
                  } else if (_statusFilter == "Completed") {
                    matchesStatus = status.contains("completed") || status.contains("delivered") || status.contains("distributed");
                  }

                  return matchesSearch && matchesStatus;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text("No donations match the filter criteria."));
                }

                final isWide = MediaQuery.of(context).size.width > 800;
                if (isWide) {
                  return GridView.builder(
                    itemCount: filteredDocs.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 310,
                    ),
                    itemBuilder: (context, index) {
                      return _buildDonationCard(
                        context,
                        filteredDocs[index],
                        cardBg,
                        isDark,
                        themeColor,
                      );
                    },
                  );
                } else {
                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      return _buildDonationCard(
                        context,
                        filteredDocs[index],
                        cardBg,
                        isDark,
                        themeColor,
                      );
                    },
                  );
                }
              },
            ),
          )
        ],
      ),
    );
  }

  void _showAssignVolunteerDialog(BuildContext context, String donationId, String clothesName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Assign Volunteer for $clothesName"),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'Volunteer')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text("No registered active volunteers found.");
                }

                final volunteers = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: volunteers.length,
                  itemBuilder: (context, index) {
                    final doc = volunteers[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final String vName = data['name'] ?? "Volunteer";
                    final String vId = doc.id;

                    return ListTile(
                      title: Text(vName),
                      subtitle: Text(data['email'] ?? ""),
                      trailing: const Icon(Icons.add, color: Colors.green),
                      onTap: () async {
                        Navigator.pop(context);
                        await http.post(
                          Uri.parse('${AppConfig.backendUrl}/api/update-donation'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'donationId': donationId,
                            'status': 'Assigned to Volunteer',
                            'volunteerId': vId,
                            'volunteerName': vName,
                            'assignedAt': 'serverTimestamp',
                          }),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _showEditStatusDialog(BuildContext context, String donationId, String currentStatus) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Update Donation Status"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("Pending"),
                onTap: () async {
                  Navigator.pop(context);
                  await http.post(
                    Uri.parse('${AppConfig.backendUrl}/api/update-donation'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'donationId': donationId,
                      'status': 'Pending',
                    }),
                  );
                },
              ),
              ListTile(
                title: const Text("Accepted by NGO"),
                onTap: () async {
                  Navigator.pop(context);
                  await http.post(
                    Uri.parse('${AppConfig.backendUrl}/api/update-donation'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'donationId': donationId,
                      'status': 'Accepted by NGO',
                    }),
                  );
                },
              ),
              ListTile(
                title: const Text("Assigned to Volunteer"),
                onTap: () async {
                  Navigator.pop(context);
                  await http.post(
                    Uri.parse('${AppConfig.backendUrl}/api/update-donation'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'donationId': donationId,
                      'status': 'Assigned to Volunteer',
                    }),
                  );
                },
              ),
              ListTile(
                title: const Text("Picked Up"),
                onTap: () async {
                  Navigator.pop(context);
                  await http.post(
                    Uri.parse('${AppConfig.backendUrl}/api/update-donation'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'donationId': donationId,
                      'status': 'Picked Up',
                    }),
                  );
                },
              ),
              ListTile(
                title: const Text("Delivered"),
                onTap: () async {
                  Navigator.pop(context);
                  await http.post(
                    Uri.parse('${AppConfig.backendUrl}/api/update-donation'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'donationId': donationId,
                      'status': 'Delivered',
                    }),
                  );
                },
              ),
              ListTile(
                title: const Text("Completed"),
                onTap: () async {
                  Navigator.pop(context);
                  await http.post(
                    Uri.parse('${AppConfig.backendUrl}/api/update-donation'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'donationId': donationId,
                      'status': 'Completed',
                    }),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusBgColor(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('pending')) return Colors.orange.withOpacity(0.1);
    if (lower.contains('accepted')) return Colors.teal.withOpacity(0.1);
    if (lower.contains('assigned')) return Colors.indigo.withOpacity(0.1);
    if (lower.contains('picked')) return Colors.purple.withOpacity(0.1);
    if (lower.contains('completed') || lower.contains('delivered') || lower.contains('distributed')) return Colors.green.withOpacity(0.1);
    return Colors.grey.withOpacity(0.1);
  }

  Color _getStatusTextColor(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('pending')) return Colors.orange.shade800;
    if (lower.contains('accepted')) return Colors.teal.shade800;
    if (lower.contains('assigned')) return Colors.indigo.shade800;
    if (lower.contains('picked')) return Colors.purple.shade800;
    if (lower.contains('completed') || lower.contains('delivered') || lower.contains('distributed')) return Colors.green.shade800;
    return Colors.grey.shade800;
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

                  final String email = data['email'] ?? "No Email";
                  final String profileImage = data['profileImage'] ?? "";
                  final bool isActive = status.toLowerCase() == 'active';

                  return Card(
                    color: cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      ),
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: themeColor.withOpacity(0.1),
                                backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
                                child: profileImage.isEmpty ? Icon(Icons.person, color: themeColor, size: 28) : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      email,
                                      style: const TextStyle(color: Colors.grey, fontSize: 12.5),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isActive ? "Active" : "Inactive",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    "$totalAssigned",
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const Text("Assigned Tasks", style: TextStyle(color: Colors.grey, fontSize: 11)),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    "$completedTasks",
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                  const Text("Completed Tasks", style: TextStyle(color: Colors.grey, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(foregroundColor: themeColor),
                                  onPressed: () {
                                    // View Details Dialog
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Volunteer Details"),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Center(
                                              child: CircleAvatar(
                                                radius: 40,
                                                backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
                                                child: profileImage.isEmpty ? const Icon(Icons.person, size: 40) : null,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Text("Name: $name", style: const TextStyle(fontWeight: FontWeight.bold)),
                                            Text("Email: $email"),
                                            Text("Phone: $phone"),
                                            Text("Status: $status"),
                                            Text("Assigned: $totalAssigned"),
                                            Text("Completed: $completedTasks"),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text("Close"),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.info_outline, size: 16),
                                  label: const Text("View", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ),
                              Expanded(
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                                  onPressed: () {
                                    // Edit Status Dialog
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Edit Status"),
                                        content: Text("Change status for $name?"),
                                        actions: [
                                          TextButton(
                                            onPressed: () async {
                                              Navigator.pop(context);
                                              await FirebaseFirestore.instance.collection('users').doc(vid).update({'status': 'Active'});
                                            },
                                            child: const Text("Activate (Active)", style: TextStyle(color: Colors.green)),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              Navigator.pop(context);
                                              await FirebaseFirestore.instance.collection('users').doc(vid).update({'status': 'Suspended'});
                                            },
                                            child: const Text("Suspend (Inactive)", style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                  label: const Text("Edit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ),
                              Expanded(
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  onPressed: () {
                                    // Delete Confirmation
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Delete Volunteer"),
                                        content: Text("Are you sure you want to delete $name from the system?"),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text("Cancel"),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                            onPressed: () async {
                                              Navigator.pop(context);
                                              await FirebaseFirestore.instance.collection('users').doc(vid).delete();
                                            },
                                            child: const Text("Delete", style: TextStyle(color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.delete_outline, size: 16),
                                  label: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ),
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
                          await http.post(
                            Uri.parse('${AppConfig.backendUrl}/api/update-donation'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({
                              'donationId': did,
                              'status': 'Assigned to Volunteer',
                              'volunteerId': vid,
                              'volunteerName': vName,
                              'assignedAt': 'serverTimestamp',
                            }),
                          );
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
// SYSTEM REPORTS & EXPORT PANEL (LIVE ANALYTICS & EXPORTS)
// ----------------------------------------------------
class _ReportsPanel extends StatefulWidget {
  final Color themeColor;
  const _ReportsPanel({required this.themeColor});

  @override
  State<_ReportsPanel> createState() => _ReportsPanelState();
}

class _ReportsPanelState extends State<_ReportsPanel> {
  String _timeFilter = "All Time";
  String _statusFilter = "All Statuses";
  String _searchQuery = "";
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesTimeFilter(DateTime? date) {
    if (date == null) return true;
    final now = DateTime.now();
    switch (_timeFilter) {
      case "Daily":
        return now.difference(date).inDays < 1;
      case "Weekly":
        return now.difference(date).inDays < 7;
      case "Monthly":
        return now.difference(date).inDays < 30;
      case "Yearly":
        return now.difference(date).inDays < 365;
      default:
        return true;
    }
  }

  void _triggerExport(List<QueryDocumentSnapshot> filteredDonations, String format) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = "Report_${_timeFilter.replaceAll(' ', '_')}_${_statusFilter.replaceAll(' ', '_')}_$timestamp";
    String fullFileName = "";

    try {
      // Get safe, platform-compliant application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final reportsDir = Directory("${appDir.path}/EchoThreadReports");
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }
      final String filePath = "${reportsDir.path}/";

      if (format == "Excel") {
        fullFileName = "$filename.xlsx";
        final excel = Excel.createExcel();
        const sheetName = "Reports";
        final sheet = excel[sheetName];
        if (excel.tables.containsKey("Sheet1") && sheetName != "Sheet1") {
          excel.delete("Sheet1");
        }

        // CSV/Excel Headers
        final List<CellValue> headers = [
          TextCellValue("Donation ID"),
          TextCellValue("Donor Name"),
          TextCellValue("Garments Type"),
          TextCellValue("Quantity"),
          TextCellValue("Location"),
          TextCellValue("NGO Hub"),
          TextCellValue("Volunteer Assigned"),
          TextCellValue("Status"),
          TextCellValue("Created At")
        ];
        sheet.appendRow(headers);

        for (final doc in filteredDonations) {
          final d = doc.data() as Map<String, dynamic>;
          final String id = doc.id;
          final String donor = d['donorName'] ?? "N/A";
          final String clothes = d['clothes'] ?? "N/A";
          final int qty = int.tryParse(d['quantity']?.toString() ?? '0') ?? 0;
          final String loc = d['location'] ?? "N/A";
          final String ngo = d['ngoName'] ?? "Unassigned";
          final String volunteer = d['volunteerName'] ?? "Unassigned";
          final String status = d['status'] ?? "Pending";
          String dateStr = "N/A";
          if (d['createdAt'] != null) {
            dateStr = (d['createdAt'] as Timestamp).toDate().toString();
          }
          sheet.appendRow([
            TextCellValue(id),
            TextCellValue(donor),
            TextCellValue(clothes),
            IntCellValue(qty),
            TextCellValue(loc),
            TextCellValue(ngo),
            TextCellValue(volunteer),
            TextCellValue(status),
            TextCellValue(dateStr)
          ]);
        }

        final file = File("$filePath$fullFileName");
        final bytes = excel.save();
        if (bytes != null) {
          await file.writeAsBytes(bytes);
        } else {
          throw Exception("Failed to encode Excel data.");
        }
      } else {
        fullFileName = "$filename.pdf";
        final pdf = pw.Document();

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(24),
            header: (pw.Context context) {
              return pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "EchoThread Donation System Report",
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple900),
                      ),
                      pw.Text(
                        DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Divider(thickness: 1, color: PdfColors.grey300),
                  pw.SizedBox(height: 8),
                ],
              );
            },
            footer: (pw.Context context) {
              return pw.Column(
                children: [
                  pw.Divider(thickness: 1, color: PdfColors.grey300),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("EchoThread Admin Portal Reports Console", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                      pw.Text("Page ${context.pageNumber} of ${context.pagesCount}", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                    ],
                  ),
                ],
              );
            },
            build: (pw.Context context) {
              return [
                pw.Text("Report Summary", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Timeframe: $_timeFilter", style: const pw.TextStyle(fontSize: 9)),
                        pw.Text("Status Filter: $_statusFilter", style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Total Records: ${filteredDonations.length}", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 14),
                pw.Table.fromTextArray(
                  headers: [
                    "ID",
                    "Donor Name",
                    "Garment Type",
                    "Qty",
                    "NGO Hub",
                    "Volunteer Assigned",
                    "Status",
                    "Date"
                  ],
                  data: filteredDonations.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final String id = doc.id.length > 6 ? doc.id.substring(0, 6) : doc.id;
                    final String donor = d['donorName'] ?? "N/A";
                    final String clothes = d['clothes'] ?? "N/A";
                    final String qty = (d['quantity'] ?? "0").toString();
                    final String ngo = d['ngoName'] ?? "Unassigned";
                    final String volunteer = d['volunteerName'] ?? "Unassigned";
                    final String status = d['status'] ?? "Pending";
                    String dateStr = "N/A";
                    if (d['createdAt'] != null) {
                      final date = (d['createdAt'] as Timestamp).toDate();
                      dateStr = "${date.day}/${date.month}/${date.year}";
                    }
                    return [id, donor, clothes, qty, ngo, volunteer, status, dateStr];
                  }).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple800),
                  cellStyle: const pw.TextStyle(fontSize: 7),
                  alternateCellStyle: const pw.TextStyle(fontSize: 7, color: PdfColors.grey900),
                  alternateRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  cellAlignment: pw.Alignment.centerLeft,
                  headerAlignment: pw.Alignment.centerLeft,
                ),
              ];
            },
          ),
        );

        final file = File("$filePath$fullFileName");
        await file.writeAsBytes(await pdf.save());
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green),
                const SizedBox(width: 8),
                const Text("Export Successful"),
              ],
            ),
            content: Text("Report exported successfully to:\n\nPath: $filePath$fullFileName\nFormat: $format"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
            ],
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint("[ADMIN_DASHBOARD] Export failed error: $e\n$stackTrace");
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text("Export Failed"),
              ],
            ),
            content: Text("An error occurred while generating the $format report:\n\n$e"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
            ],
          ),
        );
      }
    }
  }

  void _triggerPrintMock(List<QueryDocumentSnapshot> filteredDonations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.print, color: Colors.blue),
            SizedBox(width: 8),
            Text("Mock Print Spooler"),
          ],
        ),
        content: SizedBox(
          width: 500,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Print Preview Document", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      "EchoThread Spooled Print Job\n"
                      "Timestamp: ${DateTime.now()}\n"
                      "Filter Profile: $_timeFilter | $_statusFilter\n"
                      "Total Pages: 1\n"
                      "====================================\n\n" +
                      filteredDonations.map((e) {
                        final d = e.data() as Map<String, dynamic>;
                        return "Donation ID: ${e.id}\n"
                            "Donor: ${d['donorName'] ?? 'N/A'}\n"
                            "Garment: ${d['clothes'] ?? 'N/A'} [Qty: ${d['quantity'] ?? '0'}]\n"
                            "NGO: ${d['ngoName'] ?? 'Unassigned'}\n"
                            "Status: ${d['status'] ?? 'Pending'}\n"
                            "------------------------------------";
                      }).join("\n"),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Sent document to virtual printer spools successfully! 🖨️"), backgroundColor: Colors.green),
              );
            },
            icon: const Icon(Icons.print, color: Colors.white),
            label: const Text("Print", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textPrimary = isDark ? Colors.white.withOpacity(0.9) : Colors.black87;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('donations').snapshots(),
      builder: (context, donationSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, userSnapshot) {
            if (donationSnapshot.connectionState == ConnectionState.waiting ||
                userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
            }

            final donations = donationSnapshot.data?.docs ?? [];
            final users = userSnapshot.data?.docs ?? [];

            // Dynamic count aggregation
            final totalNGOs = users.where((u) => (u.data() as Map<String, dynamic>)['role'] == "NGO").length;
            final totalVolunteers = users.where((u) => (u.data() as Map<String, dynamic>)['role'] == "Volunteer").length;
            final totalDonors = users.where((u) => (u.data() as Map<String, dynamic>)['role'] == "Donor").length;

            // Apply filters & search to donations list
            final filteredDonations = donations.where((doc) {
              final d = doc.data() as Map<String, dynamic>;
              
              // 1. Search Query
              final String donorName = (d['donorName'] ?? "").toString().toLowerCase();
              final String clothes = (d['clothes'] ?? "").toString().toLowerCase();
              final String id = doc.id.toLowerCase();
              final bool matchesSearch = donorName.contains(_searchQuery) ||
                  clothes.contains(_searchQuery) ||
                  id.contains(_searchQuery);

              // 2. Status Filter
              final String status = d['status'] ?? "Pending";
              bool matchesStatus = true;
              if (_statusFilter != "All Statuses") {
                if (_statusFilter == "Pending Pickups") {
                  matchesStatus = status == 'Pending' || status == 'Accepted by NGO' || status == 'Assigned to Volunteer';
                } else if (_statusFilter == "Completed") {
                  matchesStatus = status == 'Delivered' || status == 'Completed' || status == 'Distributed';
                } else {
                  matchesStatus = status == _statusFilter;
                }
              }

              // 3. Time Filter
              final DateTime? createdDate = (d['createdAt'] as Timestamp?)?.toDate();
              final bool matchesTime = _matchesTimeFilter(createdDate);

              return matchesSearch && matchesStatus && matchesTime;
            }).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Operational System Reports Console",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Analytics card grids
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: MediaQuery.of(context).size.width > 800 ? 6 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _buildMiniStatCard("Total Donations", donations.length.toString(), Colors.blue, cardBg, textPrimary),
                      _buildMiniStatCard("Filtered Match", filteredDonations.length.toString(), Colors.purple, cardBg, textPrimary),
                      _buildMiniStatCard("Total NGOs", totalNGOs.toString(), Colors.orange, cardBg, textPrimary),
                      _buildMiniStatCard("Volunteers Count", totalVolunteers.toString(), Colors.indigo, cardBg, textPrimary),
                      _buildMiniStatCard("Donor Registry", totalDonors.toString(), Colors.teal, cardBg, textPrimary),
                      _buildMiniStatCard("Completed Handshakes", donations.where((doc) {
                        final s = (doc.data() as Map<String, dynamic>)['status'] ?? '';
                        return s == 'Delivered' || s == 'Completed' || s == 'Distributed';
                      }).length.toString(), Colors.green, cardBg, textPrimary),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Filter & Search Controls card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: "Search by Donor, Garment type, or ID...",
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      _searchQuery = val.trim().toLowerCase();
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => _triggerPrintMock(filteredDonations),
                                icon: const Icon(Icons.print, color: Colors.white, size: 18),
                                label: const Text("Print Mock", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value: _timeFilter,
                                  decoration: InputDecoration(
                                    labelText: "Timeframe",
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: "All Time", child: Text("All Time")),
                                    DropdownMenuItem(value: "Daily", child: Text("Daily")),
                                    DropdownMenuItem(value: "Weekly", child: Text("Weekly")),
                                    DropdownMenuItem(value: "Monthly", child: Text("Monthly")),
                                    DropdownMenuItem(value: "Yearly", child: Text("Yearly")),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _timeFilter = val;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value: _statusFilter,
                                  decoration: InputDecoration(
                                    labelText: "Status",
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: "All Statuses", child: Text("All Statuses")),
                                    DropdownMenuItem(value: "Pending", child: Text("Pending")),
                                    DropdownMenuItem(value: "Pending Pickups", child: Text("Pending Pickups")),
                                    DropdownMenuItem(value: "Completed", child: Text("Completed")),
                                    DropdownMenuItem(value: "Accepted by NGO", child: Text("Accepted by NGO")),
                                    DropdownMenuItem(value: "Assigned to Volunteer", child: Text("Assigned to Volunteer")),
                                    DropdownMenuItem(value: "Picked Up", child: Text("Picked Up")),
                                    DropdownMenuItem(value: "Delivered", child: Text("Delivered")),
                                    DropdownMenuItem(value: "Distributed", child: Text("Distributed")),
                                    DropdownMenuItem(value: "Rejected", child: Text("Rejected")),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _statusFilter = val;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Export Options bar
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Text(
                        "Filtered Records: ${filteredDonations.length}",
                        style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: filteredDonations.isEmpty ? null : () => _triggerExport(filteredDonations, "PDF"),
                            icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 16),
                            label: const Text("Export PDF", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: filteredDonations.isEmpty ? null : () => _triggerExport(filteredDonations, "Excel"),
                            icon: const Icon(Icons.table_view_outlined, color: Colors.white, size: 16),
                            label: const Text("Export Excel", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Data list matching search
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredDonations.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDonations[index];
                      final d = doc.data() as Map<String, dynamic>;
                      final status = d['status'] ?? "Pending";
                      final clothes = d['clothes'] ?? "Garments";
                      final qty = d['quantity'] ?? "0";
                      final donor = d['donorName'] ?? "Donor";
                      final ngo = d['ngoName'] ?? "Unassigned NGO";

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text("$clothes (Qty: $qty)", style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Donor: $donor | NGO Hub: $ngo\nID: ${doc.id}"),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: status == 'Delivered' || status == 'Completed' || status == 'Distributed'
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: status == 'Delivered' || status == 'Completed' || status == 'Distributed'
                                    ? Colors.green.shade800
                                    : Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMiniStatCard(String title, String val, Color color, Color bg, Color textPrimary) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.analytics_outlined, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            val,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9.5, color: Colors.grey),
          ),
        ],
      ),
    );
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
