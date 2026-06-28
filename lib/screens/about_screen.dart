import 'package:flutter/material.dart';
import 'package:echo_thread/widgets/navigation_drawer.dart';
import 'package:echo_thread/services/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeColor = theme.colorScheme.primary;
    final textOnSurface = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate('about')),
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
            Text(
              context.translate('title'),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 0.8),
            ),
            Text(
              "Version 1.0.0",
              style: TextStyle(color: textOnSurface.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500),
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
                      context.translate('about_project'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: themeColor),
                    ),
                    const Divider(height: 20),
                    Text(
                      "EchoThread is a dynamic Flutter + Firebase application designed to bridge the gap between clothing donors, active charity volunteers, and non-profit organizations (NGOs).\n\nBy facilitating transparent clothing donations and real-time pickup tracking, the platform simplifies resource routing and fosters community-led sustainability efforts.",
                      style: TextStyle(fontSize: 13.5, height: 1.4, color: textOnSurface.withOpacity(0.85)),
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
                      context.translate('about_mission'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: themeColor),
                    ),
                    const Divider(height: 20),
                    Text(
                      "We believe in a circular economy. Our mission is to reduce global landfill textile waste, encourage garment reusability, and provide essential clothing to individuals and families in need.",
                      style: TextStyle(fontSize: 13.5, height: 1.4, color: textOnSurface.withOpacity(0.85)),
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
                      context.translate('about_dev'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: themeColor),
                    ),
                    const Divider(height: 20),
                    Text(
                      "This platform is created and maintained by the EchoThread Engineering Team, focused on leveraging modern mobile frameworks and real-time backend integrations to solve social and environmental challenges.",
                      style: TextStyle(fontSize: 13.5, height: 1.4, color: textOnSurface.withOpacity(0.85)),
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
                      context.translate('about_contact'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: themeColor),
                    ),
                    const Divider(height: 20),
                    Text(
                      "For inquiries, partnerships, or NGO verification requests, please reach out to us:\n\n✉️ Email: info@echothread.org\n🌐 Website: www.echothread.org\n📍 Address: Green Plaza Tech Suite 10, Silicon Hub",
                      style: TextStyle(fontSize: 13, height: 1.5, color: textOnSurface.withOpacity(0.85)),
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
