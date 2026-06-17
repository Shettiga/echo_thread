import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echo_thread/services/theme_service.dart';
import 'package:echo_thread/widgets/navigation_drawer.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _feedbackSubjectController = TextEditingController();
  final _feedbackMessageController = TextEditingController();
  double _feedbackRating = 5.0;
  bool _isSubmittingFeedback = false;

  final _issueSubjectController = TextEditingController();
  final _issueDescriptionController = TextEditingController();
  bool _isReportingIssue = false;

  @override
  void dispose() {
    _feedbackSubjectController.dispose();
    _feedbackMessageController.dispose();
    _issueSubjectController.dispose();
    _issueDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final subject = _feedbackSubjectController.text.trim();
    final message = _feedbackMessageController.text.trim();

    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all feedback fields.")),
      );
      return;
    }

    setState(() => _isSubmittingFeedback = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? 'anonymous';
      final email = user?.email ?? 'no-email';

      await FirebaseFirestore.instance.collection('feedbacks').add({
        'userId': uid,
        'userEmail': email,
        'subject': subject,
        'message': message,
        'rating': _feedbackRating,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _feedbackSubjectController.clear();
        _feedbackMessageController.clear();
        setState(() => _feedbackRating = 5.0);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Thank You! 🎉"),
            content: const Text("Your feedback has been stored successfully. We appreciate your input to improve EchoThread!"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error submitting feedback: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingFeedback = false);
      }
    }
  }

  Future<void> _reportIssue() async {
    final subject = _issueSubjectController.text.trim();
    final description = _issueDescriptionController.text.trim();

    if (subject.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all issue fields.")),
      );
      return;
    }

    setState(() => _isReportingIssue = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? 'anonymous';
      final email = user?.email ?? 'no-email';

      await FirebaseFirestore.instance.collection('support_requests').add({
        'userId': uid,
        'userEmail': email,
        'type': 'Issue Report',
        'subject': subject,
        'description': description,
        'status': 'Open',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _issueSubjectController.clear();
        _issueDescriptionController.clear();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Issue Reported"),
            content: const Text("Our developers have been notified of your report. We will address it shortly."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error reporting issue: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isReportingIssue = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService().isDark(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Help & Support"),
      ),
      drawer: const AppNavigationDrawer(currentRoute: "help"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ❓ FAQ Section
            const Text(
              "Frequently Asked Questions",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: const [
                  ExpansionTile(
                    title: Text("How do I donate clothes?", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          "Go to the Donor Dashboard, tap 'Donate Clothes', fill in details (quantity, category, location, and photo), and submit. An NGO will accept your donation, and a volunteer will pick it up.",
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: Text("Who are the volunteers?", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          "Volunteers are verified community service individuals who handle picking up clothing items from your specified location and delivering them directly to NGO collection centers.",
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: Text("What clothes are acceptable?", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          "Please donate clean, gently used, or wearable clothing. We ask that underwear, socks, or heavily stained garments be excluded for hygiene reasons.",
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: Text("How is the CO₂ impact calculated?", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          "Our system estimates a saving of approximately 5.5kg of CO₂ emissions and 2,700 liters of water per garment reused, based on global textile recycling standards.",
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 📞 Contact Support Section
            const Text(
              "Contact Support",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.email, color: isDark ? Colors.white70 : const Color(0xFF2E7D32)),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Email Support", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text("support@echothread.org", style: TextStyle(color: Colors.black54, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.phone, color: isDark ? Colors.white70 : const Color(0xFF2E7D32)),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Phone Support", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text("+1 (800) 555-THRD (8473)", style: TextStyle(color: Colors.black54, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 📝 Report an Issue Section
            const Text(
              "Report an Issue",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _issueSubjectController,
                      decoration: const InputDecoration(labelText: "Issue Title/Subject"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _issueDescriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: "Describe what went wrong..."),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isReportingIssue ? null : _reportIssue,
                        child: _isReportingIssue
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Submit Ticket", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ⭐ Feedback Form Section
            const Text(
              "Submit App Feedback",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _feedbackSubjectController,
                      decoration: const InputDecoration(labelText: "Feedback Subject"),
                    ),
                    const SizedBox(height: 12),
                    const Text("Rating", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Row(
                      children: [
                        const Text("1 ⭐"),
                        Expanded(
                          child: Slider(
                            value: _feedbackRating,
                            min: 1.0,
                            max: 5.0,
                            divisions: 4,
                            activeColor: const Color(0xFF2E7D32),
                            onChanged: (rating) {
                              setState(() {
                                _feedbackRating = rating;
                              });
                            },
                          ),
                        ),
                        Text("${_feedbackRating.toInt()} ⭐"),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _feedbackMessageController,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: "Your suggestions & message..."),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isSubmittingFeedback ? null : _submitFeedback,
                        child: _isSubmittingFeedback
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Submit Feedback", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
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
