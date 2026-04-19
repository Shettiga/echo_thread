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

class _NGODashboardState extends State<NGODashboard> {
  String userName = "Loading...";

  @override
  void initState() {
    super.initState();
    getUserName();
  }

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
      backgroundColor: const Color(0xFFFFF3E0),
      body: SafeArea(
        child: Column(
          children: [

            // 🔹 HEADER
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE65100), Color(0xFFFFA726)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hello, $userName 👋",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      const Text("Manage donations efficiently",
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),

                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.home_work, color: Colors.orange),
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

            const Text("Donation Requests",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: const [
                  DonationCard(donor: "Rahul", items: "5 Shirts"),
                  DonationCard(donor: "Ayesha", items: "3 Jackets"),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  actionButton(context, Icons.person, "Profile"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget actionButton(BuildContext context, IconData icon, String title) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
      },
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.orange,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 5),
          Text(title),
        ],
      ),
    );
  }
}

// 📦 DONATION CARD
class DonationCard extends StatelessWidget {
  final String donor;
  final String items;

  const DonationCard({super.key, required this.donor, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.card_giftcard, color: Colors.orange),
        title: Text("Donor: $donor"),
        subtitle: Text("Items: $items"),
      ),
    );
  }
}