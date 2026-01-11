import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'dart:convert';

import '../models/card_model.dart';
import 'card_view_screen.dart'; // Βεβαιώσου ότι υπάρχει η διαδρομή

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? name;
  String? email;
  String? userType;
  String? uid;
  BusinessCard? activeCard;
  StreamSubscription? _userSubscription;
  bool _nfcSupported = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _checkNfcSupport();
    _setupUserListener();
    _loadActiveCard();
  }

  Future<void> _checkNfcSupport() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    setState(() {
      _nfcSupported = isAvailable;
    });
  }

  void _setupUserListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data()!;
          setState(() {
            name = data["name"];
            email = data["email"];
            userType = data["type"];
          });
        }
      });
    }
  }

  Future<void> _loadActiveCard() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("cards")
          .where("is_active", isEqualTo: true)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        setState(() {
          activeCard = BusinessCard.fromMap(
            snap.docs.first.data(),
            snap.docs.first.id,
          );
        });
      }
    } catch (e) {
      print("Error loading active card for QR: $e");
    }
  }

  void _showShareCardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Επιλογή Κάρτας για NFC Share"),
        content: FutureBuilder<List<BusinessCard>>(
          future: _loadUserCardsForShare(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text("Δεν βρέθηκαν κάρτες");
            }

            final cards = snapshot.data!;

            return SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.credit_card,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(card.title),
                      subtitle: Text(card.contactInfo['name'] ?? 'Χωρίς όνομα'),
                      trailing: Icon(
                        card.hasNfc ? Icons.nfc : Icons.nfc_outlined,
                        color: card.hasNfc ? Colors.blue : Colors.grey,
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        _startNfcWriteForCard(card);
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Ακύρωση"),
          ),
        ],
      ),
    );
  }

  Future<List<BusinessCard>> _loadUserCardsForShare() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cards')
          .where('is_active', isEqualTo: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return BusinessCard.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      print("Error loading cards for share: $e");
      return [];
    }
  }

  Future<void> _startNfcWriteForCard(BusinessCard card) async {
    if (!_nfcSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Η συσκευή δεν υποστηρίζει NFC εγγραφή."),
        ),
      );
      return;
    }

    context.push('/nfc-write', extra: card);
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    uid = user.uid;

    final snap =
    await FirebaseFirestore.instance.collection("users").doc(uid).get();

    if (snap.exists) {
      final data = snap.data()!;
      setState(() {
        name = data["name"];
        email = data["email"];
        userType = data["type"];
      });
    }
  }

  Future<void> _startNfcScan() async {
    if (!_nfcSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Η συσκευή δεν υποστηρίζει NFC."),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Πλησίασε το NFC tag..."),
      ),
    );

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (tag) async {
          final tagData = tag.data;
          try {
            // Προσπαθούμε να πάρουμε JSON string
            String jsonString;
            if (tagData is Map && tagData.containsKey('ndef')) {
              final ndef = tagData['ndef'];
              if (ndef is Map && ndef.containsKey('cachedMessage')) {
                final records = ndef['cachedMessage']['records'];
                if (records is List && records.isNotEmpty) {
                  jsonString = utf8.decode(records.first['payload'].sublist(3));
                  final Map<String, dynamic> map = jsonDecode(jsonString);
                  final card = BusinessCard.fromMap(map, map['cardId']);
                  if (mounted) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CardViewScreen(card: card),
                        ));
                  }
                }
              }
            }
          } catch (e) {
            print("Error reading NFC tag: $e");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Σφάλμα ανάγνωσης κάρτας NFC")),
            );
          }

          await NfcManager.instance.stopSession();
        },
      );
    } catch (e) {
      await NfcManager.instance.stopSession();
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        GoRouter.of(context).go('/login');
      }
    } catch (e) {
      print("Logout error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Σφάλμα κατά την αποσύνδεση")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "NexusLink Dashboard",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            color: Colors.white,
            onPressed: () => _openMobileScanner(context),
            tooltip: "Σκανάρισμα QR",
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            color: Colors.white,
            onPressed: () => context.go('/analytics'),
            tooltip: "Στατιστικά",
          ),
          IconButton(
            icon: const Icon(Icons.person),
            color: Colors.white,
            onPressed: () => context.go('/profile'),
            tooltip: "Προφίλ",
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.white,
            onPressed: _logout,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadUser();
          await _loadActiveCard();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildProfileCard(),
              const SizedBox(height: 25),
              _buildCardsManagementCard(),
              const SizedBox(height: 25),
              _buildNfcCard(),
              const SizedBox(height: 25),

              if (activeCard != null) _buildQrPreview(activeCard!),
              if (activeCard == null)
                const Text(
                  "Δεν έχεις ενεργή κάρτα για εμφάνιση QR",
                  style: TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Προσθέστε αυτή τη μέθοδο στην κλάση _HomeScreenState
  Future<void> _openMobileScanner(BuildContext context) async {
    // Πλοήγηση απευθείας στο QrScannerScreen
    context.push('/qr-scanner');
  }


  Widget _buildProfileCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.blue.shade100,
              child: Icon(Icons.person, size: 40, color: Colors.blue.shade700),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name ?? "—",
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    email ?? "—",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userType == "pro" ? "Professional Account" : "User Account",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blueAccent.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNfcCard() {
    return GestureDetector(
      onTap: _showShareCardDialog,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.nfc_rounded,
                size: 65,
                color: _nfcSupported ? Colors.blueAccent : Colors.grey,
              ),
              const SizedBox(height: 10),
              Text(
                "Share via NFC",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _nfcSupported ? Colors.blueAccent : Colors.grey,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _nfcSupported
                    ? "Πάτησε για επιλογή κάρτας προς share"
                    : "Η συσκευή δεν υποστηρίζει NFC.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrPreview(BusinessCard card) {
    // Δημιουργούμε JSON για QR με τη σωστή δομή
    final qrData = jsonEncode({
      'type': 'nexuslink_business_card',
      'cardId': card.cardId,
      'ownerId': card.ownerId,
      'title': card.title,
      'isPublic': card.isPublic,
      'contactInfo': {
        'name': card.contactInfo['name'] ?? '',
        'position': card.contactInfo['position'] ?? '',
        'company': card.contactInfo['company'] ?? '',
        'phone': card.contactInfo['phone'] ?? '',
        'email': card.contactInfo['email'] ?? '',
        'website': card.contactInfo['website'] ?? '',
        'address': card.contactInfo['address'] ?? '',
      },
      'socialLinks': card.socialLinks,
      'customActions': card.customActions,
      'timestamp': DateTime.now().toIso8601String(),
    });

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Το QR μου",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            QrImageView(
              data: qrData,
              size: 170,
            ),
            const SizedBox(height: 10),
            Text(
              "Σάρωσε το για ταυτοποίηση",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            // Προσθήκη κουμπιού για δοκιμή
            const SizedBox(height: 15),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text("Δοκιμή Σκανάρισματος"),
              onPressed: () {
                // Δοκιμή: Προσομοίωση σκανάρισματος με τα ίδια δεδομένα
                final testCard = BusinessCard.fromQrData(qrData);
                context.push('/card-view', extra: testCard);
              },
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCardsManagementCard() {
    return GestureDetector(
      onTap: () => context.go('/cards'),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.credit_card,
                size: 65,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 10),
              Text(
                "Διαχείριση Καρτών",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Δημιούργησε και διαχείρισε τις ψηφιακές σου κάρτες",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              )
            ],
          ),
        ),
      ),
    );
  }
}
