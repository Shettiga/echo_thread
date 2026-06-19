import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echo_thread/screens/login_screen.dart';
import 'package:echo_thread/screens/profile_screen.dart';
import 'package:echo_thread/screens/settings_screen.dart';
import 'package:echo_thread/screens/help_screen.dart';
import 'package:echo_thread/screens/about_screen.dart';
import 'package:echo_thread/screens/admin_dashboard.dart';
import 'package:echo_thread/screens/donor_dashboard.dart';
import 'package:echo_thread/screens/ngo_dashboard.dart';
import 'package:echo_thread/screens/volunteer_dashboard.dart';
import 'package:echo_thread/services/theme_service.dart';

class AppNavigationDrawer extends StatefulWidget {
  final String currentRoute;
  const AppNavigationDrawer({super.key, required this.currentRoute});

  @override
  State<AppNavigationDrawer> createState() => _AppNavigationDrawerState();
}

class _AppNavigationDrawerState extends State<AppNavigationDrawer> {
  String userName = "Loading...";
  String userRole = "";
  String? profileImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (mounted) {
            setState(() {
              userName = data['name'] ?? "User";
              userRole = data['role'] ?? "Donor";
              profileImage = data['profileImage'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint('[DRAWER] Error fetching user data: $e');
    }
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out of EchoThread?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await FirebaseAuth.instance.signOut();
              if (mounted) {
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

  Color _getRoleColor(String role) {
    final r = role.toLowerCase();
    if (r == 'ngo') {
      return const Color(0xFFE65100);
    } else if (r == 'volunteer') {
      return const Color(0xFF1565C0);
    } else if (r == 'admin') {
      return const Color(0xFF673AB7);
    } else {
      return const Color(0xFF2E7D32);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();
    final isDark = themeService.isDark(context);
    final themeColor = _getRoleColor(userRole);

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Column(
        children: [
          // Drawer Header
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
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: profileImage != null && profileImage!.isNotEmpty
                      ? NetworkImage(profileImage!)
                      : null,
                  child: profileImage == null || profileImage!.isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          userRole.isEmpty ? "Loading..." : userRole,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                _buildDrawerItem(
                  icon: Icons.dashboard_outlined,
                  title: "Dashboard",
                  routeName: "dashboard",
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.currentRoute != "dashboard") {
                      final r = userRole.toLowerCase();
                      Widget targetDashboard;
                      if (r == 'admin') {
                        targetDashboard = const AdminDashboard();
                      } else if (r == 'ngo') {
                        targetDashboard = const NGODashboard();
                      } else if (r == 'volunteer') {
                        targetDashboard = const VolunteerDashboard();
                      } else {
                        targetDashboard = const DonorDashboard();
                      }
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => targetDashboard),
                        (route) => false,
                      );
                    }
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.person_outline,
                  title: "My Profile",
                  routeName: "profile",
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.currentRoute != "profile") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    }
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  title: "Settings",
                  routeName: "settings",
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.currentRoute != "settings") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    }
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline,
                  title: "Help & Support",
                  routeName: "help",
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.currentRoute != "help") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HelpScreen()),
                      );
                    }
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.info_outline,
                  title: "About EchoThread",
                  routeName: "about",
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.currentRoute != "about") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      );
                    }
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    "Logout",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String routeName,
    required VoidCallback onTap,
  }) {
    final isSelected = widget.currentRoute == routeName;
    final themeColor = _getRoleColor(userRole);
    final isDark = ThemeService().isDark(context);

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? (isDark ? Colors.white : themeColor)
            : (isDark ? Colors.white70 : Colors.black54),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? (isDark ? Colors.white : themeColor)
              : (isDark ? Colors.white.withOpacity(0.9) : Colors.black87),
        ),
      ),
      selected: isSelected,
      selectedTileColor: isDark
          ? Colors.white.withOpacity(0.08)
          : themeColor.withOpacity(0.08),
      onTap: onTap,
    );
  }
}
