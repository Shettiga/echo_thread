import 'package:flutter/material.dart';
import 'package:echo_thread/widgets/navigation_drawer.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF2E7D32);

    return Scaffold(
      appBar: AppBar(
        title: const Text("About EchoThread"),
      ),
      drawer: const AppNavigationDrawer(currentRoute: "about"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🏷️ Logo and Name
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: themeColor, width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "EchoThread",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 0.8),
            ),
            const Text(
              "Version 1.0.0",
              style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 28),

            // 📜 Project Description Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Our Project",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: themeColor),
                    ),
                    const Divider(height: 20),
                    const Text(
                      "EchoThread is a dynamic Flutter + Firebase application designed to bridge the gap between clothing donors, active charity volunteers, and non-profit organizations (NGOs).\n\nBy facilitating transparent clothing donations and real-time pickup tracking, the platform simplifies resource routing and fosters community-led sustainability efforts.",
                      style: TextStyle(fontSize: 13.5, height: 1.4, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 🎯 Mission Statement Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Our Mission",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: themeColor),
                    ),
                    const Divider(height: 20),
                    const Text(
                      "We believe in a circular economy. Our mission is to reduce global landfill textile waste, encourage garment reusability, and provide essential clothing to individuals and families in need.",
                      style: TextStyle(fontSize: 13.5, height: 1.4, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 👥 Developer Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Developer Information",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: themeColor),
                    ),
                    const Divider(height: 20),
                    const Text(
                      "This platform is created and maintained by the EchoThread Engineering Team, focused on leveraging modern mobile frameworks and real-time backend integrations to solve social and environmental challenges.",
                      style: TextStyle(fontSize: 13.5, height: 1.4, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 📞 Contact Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Contact Information",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: themeColor),
                    ),
                    const Divider(height: 20),
                    const Text(
                      "For inquiries, partnerships, or NGO verification requests, please reach out to us:\n\n✉️ Email: info@echothread.org\n🌐 Website: www.echothread.org\n📍 Address: Green Plaza Tech Suite 10, Silicon Hub",
                      style: TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
