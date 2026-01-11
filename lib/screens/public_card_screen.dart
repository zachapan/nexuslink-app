import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PublicCardScreen extends StatelessWidget {
  final String cardId;

  const PublicCardScreen({super.key, required this.cardId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('public_cards')
            .doc(cardId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "Η κάρτα δεν είναι διαθέσιμη",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final contact = data['contactInfo'] ?? {};
          final social = data['socialLinks'] ?? {};

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _info("Όνομα", contact['name']),
                  _info("Θέση", contact['position']),
                  _info("Εταιρεία", contact['company']),
                  _info("Email", contact['email'], isLink: true),
                  _info("Τηλέφωνο", contact['phone'], isLink: true),
                  _info("Website", contact['website'], isLink: true),

                  const SizedBox(height: 24),
                  const Text(
                    "Social",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  _info("Facebook", social['facebook'], isLink: true),
                  _info("Instagram", social['instagram'], isLink: true),
                  _info("Twitter / X", social['twitter'], isLink: true),
                  _info("LinkedIn", social['linkedin'], isLink: true),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _info(String label, String? value, {bool isLink = false}) {
    if (value == null || value.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        "$label: $value",
        style: TextStyle(
          fontSize: 15,
          color: isLink ? Colors.blue : Colors.black,
        ),
      ),
    );
  }
}
