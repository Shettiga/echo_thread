import 'package:flutter/material.dart';
import 'donate_clothes_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class DonorDashboard extends StatefulWidget {
  const DonorDashboard({super.key});

  @override
  State<DonorDashboard> createState() => _DonorDashboardState();
}

class _DonorDashboardState extends State<DonorDashboard> {
  String userName = "Loading...";

  @override
  void initState() {
    super.initState();
    getUserName();
  }

  // 🔥 Fetch user name from Firebase
  Future<void> getUserName() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      var data = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      setState(() {
        userName = data.data()?['name'] ?? "User";
      });
    }
  }

  // 🔴 Logout Function
  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🔹 HEADER
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  
                  // 👤 USER INFO
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hello, $userName 👋",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      const Text("Ready to make an impact today?",
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),

                  // 🔴 PROFILE + LOGOUT
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: Colors.green),
                      ),
                      const SizedBox(width: 10),

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

            // 🌍 IMPACT CARD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6)
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ImpactItem(title: "Clothes Donated", value: "12"),
                    ImpactItem(title: "People Helped", value: "8"),
                    ImpactItem(title: "CO₂ Saved", value: "5kg"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // 🔸 TITLE
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text("Quick Actions",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 15),

            // 🔹 GRID
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  children: [
                    dashboardCard(
                      context,
                      Icons.add_box,
                      "Donate Clothes",
                      const DonateClothesScreen(),
                    ),
                    dashboardCard(
                      context,
                      Icons.local_shipping,
                      "Track Donation",
                      const PlaceholderScreen(title: "Track Donation"),
                    ),
                    dashboardCard(
                      context,
                      Icons.eco,
                      "Impact Report",
                      const PlaceholderScreen(title: "Impact Report"),
                    ),
                    dashboardCard(
                      context,
                      Icons.person,
                      "Profile",
                      const ProfileScreen(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 CARD FUNCTION
  Widget dashboardCard(
      BuildContext context, IconData icon, String title, Widget screen) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFA5D6A7), Color(0xFF66BB6A)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 10),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
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

  const ImpactItem({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green)),
        const SizedBox(height: 5),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// 📌 PLACEHOLDER
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          "$title Coming Soon 🚀",
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  
}