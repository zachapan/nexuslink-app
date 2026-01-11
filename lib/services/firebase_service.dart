import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // User Management
  static Future<void> createUserProfile(String uid, Map<String, dynamic> userData) async {
    await _firestore.collection('users').doc(uid).set({
      ...userData,
      'uid': uid,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  static Stream<DocumentSnapshot> getUserProfileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  // Card Management
  static Future<String> createUserCard(Map<String, dynamic> cardData) async {
    final docRef = await _firestore.collection('cards').add({
      ...cardData,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  static Stream<QuerySnapshot> getUserCards(String userId) {
    return _firestore
        .collection('cards')
        .where('ownerId', isEqualTo: userId)
        .where('is_active', isEqualTo: true)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  // Analytics & Logs
  static Future<void> logNfcScan(Map<String, dynamic> scanData) async {
    await _firestore.collection('nfc_logs').add({
      ...scanData,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateAnalytics(String userId, Map<String, dynamic> analyticsData) async {
    final date = DateTime.now().toIso8601String().split('T')[0];
    final docId = '${userId}_$date';

    await _firestore.collection('analytics').doc(docId).set({
      ...analyticsData,
      'userId': userId,
      'date': date,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get current user
  static User? get currentUser => _auth.currentUser;
}