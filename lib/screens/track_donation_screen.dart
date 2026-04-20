import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TrackDonationScreen extends StatelessWidget {
  const TrackDonationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Track Donations")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('donations')
            .where('donorId', isEqualTo: userId)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No donations yet"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(data['clothes']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Qty: ${data['quantity']}"),
                      Text("Location: ${data['location']}"),
                      Text("Status: ${data['status']}"),
                    ],
                  ),
                  trailing: _statusIcon(data['status']),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _statusIcon(String status) {
    switch (status) {
      case "Pending":
        return const Icon(Icons.hourglass_empty, color: Colors.orange);
      case "Accepted":
        return const Icon(Icons.check_circle, color: Colors.blue);
      case "Picked Up":
        return const Icon(Icons.local_shipping, color: Colors.purple);
      case "Delivered":
        return const Icon(Icons.done_all, color: Colors.green);
      default:
        return const Icon(Icons.help);
    }
  }
}