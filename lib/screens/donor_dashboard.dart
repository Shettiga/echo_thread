import 'package:flutter/material.dart';
import 'donate_clothes_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class DonorDashboard extends StatelessWidget {
  const DonorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🔹 Header Section
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
    const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Hello, Donor 👋",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 5),
        Text(
          "Ready to make an impact today?",
          style: TextStyle(color: Colors.white70),
        ),
      ],
    ),

    Row(
      children: [
        const CircleAvatar(
          radius: 25,
          backgroundColor: Colors.white,
          child: Icon(Icons.person, color: Colors.green),
        ),
        const SizedBox(width: 10),

        // 🔴 LOGOUT BUTTON
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
        ),
      ],
    ),
  ],
),
            ),

            const SizedBox(height: 20),

            // 🌍 Impact Summary Card
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    ImpactItem(title: "Clothes Donated", value: "12"),
                    ImpactItem(title: "People Helped", value: "8"),
                    ImpactItem(title: "CO₂ Saved", value: "5kg"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // 🔸 Section Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text("Quick Actions",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 15),

            // 🔹 Grid Actions
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

  // 🔹 Reusable Dashboard Card with Navigation
  Widget dashboardCard(
      BuildContext context, IconData icon, String title, Widget screen) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFA5D6A7), Color(0xFF66BB6A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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

// 🌍 Impact Item Widget
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

// 📌 Placeholder Screen for Upcoming Features
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          "$title Screen Coming Soon 🚀",
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
