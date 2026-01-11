import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../models/card_model.dart';
import '../services/nfc_writing_service.dart';

class CardsManagementScreen extends StatefulWidget {
  const CardsManagementScreen({super.key});

  @override
  State<CardsManagementScreen> createState() => _CardsManagementScreenState();
}

class _CardsManagementScreenState extends State<CardsManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;
  final NfcWritingService _nfcService = NfcWritingService();

  List<BusinessCard> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserCards();
    // ΑΥΤΟ ΕΙΝΑΙ ΠΟΛΥ ΣΗΜΑΝΤΙΚΟ: Migration υφιστάμενων καρτών
    WidgetsBinding.instance.addPostFrameCallback((_) => _migrateExistingCards());
  }

  // ΝΕΟ: Migration μεθόδος για υφιστάμενες κάρτες
  Future<void> _migrateExistingCards() async {
    if (_user == null) return;

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('cards')
          .get();

      int updatedCount = 0;

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        // Έλεγχος αν λείπει το ownerId ή είναι κενό
        if (!data.containsKey('ownerId') || data['ownerId'] == '') {
          await doc.reference.update({
            'ownerId': _user!.uid,
          });
          updatedCount++;
        }
      }

      if (updatedCount > 0) {
        print('Successfully migrated $updatedCount cards with ownerId');
        // Ξαναφόρτωσε τις κάρτες μετά το migration
        _loadUserCards();
      }

    } catch (e) {
      print('Error migrating cards: $e');
    }
  }

  Future<void> _loadUserCards() async {
    if (_user == null) {
      print('❌ User is null');
      return;
    }

    try {
      print('👤 Loading cards for user: ${_user!.uid}');

      final querySnapshot = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('cards')
          .where('is_active', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .get();

      print('✅ Query completed. Found ${querySnapshot.docs.length} documents');

      // Debug: Εκτύπωση όλων των documents και των δεδομένων τους
      for (final doc in querySnapshot.docs) {
        print('📄 Document ID: ${doc.id}');
        print('   Data: ${doc.data()}');
        print('   Has ownerId: ${doc.data().containsKey('ownerId')}');
        if (doc.data().containsKey('ownerId')) {
          print('   ownerId value: ${doc.data()['ownerId']}');
        }
      }

      final cards = querySnapshot.docs.map((doc) {
        final cardData = doc.data();
        print('🔄 Creating BusinessCard from data: $cardData');
        return BusinessCard.fromMap(cardData, doc.id);
      }).toList();

      if (mounted) {
        setState(() {
          _cards = cards;
          _isLoading = false;
        });
        print('🎉 Loaded ${_cards.length} cards successfully');
      }
    } catch (e, stackTrace) {
      print('❌ Error loading cards: $e');
      print('📋 Stack trace: $stackTrace');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _createNewCard() {
    context.go('/cards/edit');
  }

  void _editCard(BusinessCard card) {
    context.go('/cards/edit/${card.cardId}', extra: card);
  }

  void _writeToNfc(BusinessCard card) {
    context.push('/nfc-write', extra: card);
  }

  Future<void> _checkNfcAndWrite(BusinessCard card) async {
    final isNfcSupported = await _nfcService.isNfcSupported();

    if (!isNfcSupported) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Η συσκευή σας δεν υποστηρίζει NFC εγγραφή"),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    _writeToNfc(card);
  }

  Future<void> _deleteCard(String cardId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('cards')
          .doc(cardId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Η κάρτα διαγράφηκε")),
        );
        _loadUserCards();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Σφάλμα διαγραφής: $e")),
        );
      }
    }
  }

  void _showDeleteDialog(String cardId, String cardTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Διαγραφή Κάρτας"),
        content: Text("Θέλετε να διαγράψετε την κάρτα '$cardTitle';"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Άκυρο"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteCard(cardId);
            },
            child: const Text("Διαγραφή", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Διαχείριση Καρτών",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white, // ΛΕΥΚΟ ΒΕΛΟΣ
          ),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add,
              color: Colors.white, // ΛΕΥΚΟ ΣΥΜΒΟΛΟ +
            ),
            onPressed: _createNewCard,
            tooltip: "Νέα Κάρτα",
          ),
        ],
        iconTheme: const IconThemeData(
          color: Colors.white, // ΛΕΥΚΑ ΟΛΑ ΤΑ ΕΙΚΟΝΙΔΙΑ
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
          ? _buildEmptyState()
          : _buildCardsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewCard,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.credit_card,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            "Δεν υπάρχουν κάρτες",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Δημιούργησε την πρώτη σου ψηφιακή κάρτα",
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _createNewCard,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text(
              "Δημιουργία Κάρτας",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Οι Κάρτες Μου (${_cards.length})",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                final card = _cards[index];
                return _buildCardItem(card);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem(BusinessCard card) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.credit_card,
                color: Theme.of(context).colorScheme.primary,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card.contactInfo['name'] ?? 'Χωρίς όνομα',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      // Public/Private
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.public,
                            size: 14,
                            color: card.isPublic ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            card.isPublic ? 'Public' : 'Private',
                            style: TextStyle(
                              fontSize: 12,
                              color: card.isPublic ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),

                      // NFC Status
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            card.hasNfc ? Icons.nfc : Icons.nfc_outlined,
                            size: 14,
                            color: card.hasNfc ? Colors.blue : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            card.hasNfc ? 'NFC' : 'No NFC',
                            style: TextStyle(
                              fontSize: 12,
                              color: card.hasNfc ? Colors.blue : Colors.grey,
                            ),
                          ),
                        ],
                      ),

                      // Date
                      Text(
                        _formatDate(card.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // NFC Share Button - ΝΕΟ
                IconButton(
                  icon: Icon(
                    Icons.share,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () => _shareCard(card),
                  tooltip: "Share via NFC",
                ),
                IconButton(
                  icon: Icon(
                    card.hasNfc ? Icons.nfc : Icons.nfc_outlined,
                    color: card.hasNfc ? Colors.blue : Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () => _checkNfcAndWrite(card),
                  tooltip: "Εγγραφή σε NFC Tag",
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editCard(card);
                    } else if (value == 'delete') {
                      _showDeleteDialog(card.cardId!, card.title);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text("Επεξεργασία"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text("Διαγραφή"),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ΝΕΟ: Μέθοδος για share
  void _shareCard(BusinessCard card) {
    context.push('/nfc-write', extra: card);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _nfcService.dispose();
    super.dispose();
  }
}