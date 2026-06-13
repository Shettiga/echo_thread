import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TrackDonationScreen extends StatefulWidget {
  const TrackDonationScreen({super.key});

  @override
  State<TrackDonationScreen> createState() => _TrackDonationScreenState();
}

class _TrackDonationScreenState extends State<TrackDonationScreen> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    final themeColor = const Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: themeColor),
        title: Text(
          "Track Donations",
          style: TextStyle(
            color: themeColor,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('donations')
            .where('donorId', isEqualTo: userId)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.volunteer_activism_outlined, size: 84, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    "No donations yet",
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Your donations will appear here in real-time.",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          // Sort in-memory to avoid requiring composite indexes
          var docs = snapshot.data!.docs;
          docs.sort((a, b) {
            var aData = a.data() as Map<String, dynamic>;
            var bData = b.data() as Map<String, dynamic>;
            Timestamp aTime = aData['createdAt'] ?? Timestamp.now();
            Timestamp bTime = bData['createdAt'] ?? Timestamp.now();
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              bool isExpanded = _expandedIndex == index;
              String rawStatus = data['status'] ?? "Pending";
              String displayStatus = rawStatus;
              if (rawStatus == 'Accepted') displayStatus = 'Accepted by NGO';
              if (rawStatus == 'Assigned') displayStatus = 'Assigned to Volunteer';

              return AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                margin: const EdgeInsets.only(bottom: 14),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getStatusColor(rawStatus).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getStatusIcon(rawStatus),
                            color: _getStatusColor(rawStatus),
                            size: 26,
                          ),
                        ),
                        title: Text(
                          "${data['clothes']} (Qty: ${data['quantity']})",
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(rawStatus).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  displayStatus,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _getStatusColor(rawStatus),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Date: ${data['pickupDate']}",
                                style: const TextStyle(fontSize: 12, color: Colors.black45),
                              ),
                            ],
                          ),
                        ),
                        trailing: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.black38,
                        ),
                        onTap: () {
                          setState(() {
                            _expandedIndex = isExpanded ? null : index;
                          });
                        },
                      ),
                      if (isExpanded) ...[
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Pickup Location: ${data['location']}",
                                style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 20),
                              _buildVerticalStepper(
                                status: rawStatus,
                                volunteerName: data['volunteerName'],
                              ),
                            ],
                          ),
                        )
                      ]
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

  Widget _buildVerticalStepper({required String status, String? volunteerName}) {
    final steps = [
      "Pending",
      "Accepted by NGO",
      "Assigned to Volunteer",
      "Accepted by Volunteer",
      "Picked Up",
      "Delivered",
      "Distributed"
    ];

    String normalizedStatus = status;
    if (status == 'Accepted') normalizedStatus = 'Accepted by NGO';
    if (status == 'Assigned') normalizedStatus = 'Assigned to Volunteer';

    int currentIdx = steps.indexOf(normalizedStatus);
    if (currentIdx == -1) {
      currentIdx = 0;
    }

    final Map<String, String> stepDescriptions = {
      "Pending": "Donation request submitted. Awaiting NGO review.",
      "Accepted by NGO": "NGO accepted your donation. Selecting a volunteer.",
      "Assigned to Volunteer": "Volunteer ${volunteerName ?? ''} has been assigned to pickup.",
      "Accepted by Volunteer": "Volunteer accepted task. Starting pickup soon.",
      "Picked Up": "Volunteer has collected the clothes and is in transit.",
      "Delivered": "Clothes successfully received at the NGO hub.",
      "Distributed": "Clothes have been successfully given to people in need! ❤️",
    };

    return Column(
      children: List.generate(steps.length, (index) {
        final stepName = steps[index];
        final isCompleted = index <= currentIdx;
        final isActive = index == currentIdx;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isActive ? 24 : 18,
                  height: isActive ? 24 : 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                    border: isActive ? Border.all(color: Colors.green.shade100, width: 4) : null,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check,
                      size: isActive ? 12 : 10,
                      color: isCompleted ? Colors.white : Colors.transparent,
                    ),
                  ),
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 2,
                    height: 36,
                    color: index < currentIdx ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stepName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                        color: isCompleted ? Colors.black87 : Colors.black38,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stepDescriptions[stepName] ?? "",
                      style: TextStyle(
                        fontSize: 12,
                        color: isCompleted ? Colors.black54 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Pending":
        return Colors.orange.shade700;
      case "Accepted":
      case "Accepted by NGO":
        return Colors.blue.shade700;
      case "Assigned":
      case "Assigned to Volunteer":
        return Colors.indigo.shade700;
      case "Accepted by Volunteer":
        return Colors.deepPurple.shade700;
      case "Picked Up":
        return Colors.purple.shade700;
      case "Delivered":
        return Colors.green.shade700;
      case "Distributed":
        return Colors.teal.shade700;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case "Pending":
        return Icons.hourglass_top_outlined;
      case "Accepted":
      case "Accepted by NGO":
        return Icons.check_circle_outline;
      case "Assigned":
      case "Assigned to Volunteer":
        return Icons.person_pin_outlined;
      case "Accepted by Volunteer":
        return Icons.thumb_up_outlined;
      case "Picked Up":
        return Icons.local_shipping_outlined;
      case "Delivered":
        return Icons.verified_outlined;
      case "Distributed":
        return Icons.volunteer_activism_outlined;
      default:
        return Icons.help_outline;
    }
  }
}