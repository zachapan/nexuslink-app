import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';

class UsageTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Track NFC Scan
  Future<void> trackNfcScan({
    required String cardId,
    String? scannerUserId,
    Map<String, dynamic>? additionalData,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Get user subscription data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final subscriptionPlan = userData['subscription_plan'] ?? 'free';
      final maxScans = userData['max_scans'] ?? 10;
      final usedScans = userData['used_scans'] ?? 0;

      // Check if user has reached scan limit
      if (subscriptionPlan == 'free' && usedScans >= maxScans) {
        throw Exception('Έχετε φτάσει το όριο των $maxScans scans. Αναβαθμίστε για περισσότερα.');
      }

      // Get device info
      final deviceInfo = await _getDeviceInfo();
      final location = await _getLocationInfo(); // Θα υλοποιήσουμε μετά

      // Create scan log
      final scanData = {
        'userId': user.uid,
        'cardId': cardId,
        'scannerUserId': scannerUserId,
        'deviceInfo': deviceInfo,
        'location': location,
        'timestamp': FieldValue.serverTimestamp(),
        'scanType': 'nfc',
        'additionalData': additionalData ?? {},
      };

      // Add to nfc_logs collection
      await _firestore.collection('nfc_logs').add(scanData);

      // Update user scan count
      await _updateUserScanCount(user.uid, usedScans + 1);

      // Update analytics
      await _updateAnalytics(user.uid, cardId);

      print('NFC scan tracked successfully');
    } catch (e) {
      print('Error tracking NFC scan: $e');
      rethrow;
    }
  }

  // Track QR Scan
  Future<void> trackQrScan({
    required String cardId,
    String? scannerUserId,
    Map<String, dynamic>? additionalData,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Similar logic to NFC scan
      final scanData = {
        'userId': user.uid,
        'cardId': cardId,
        'scannerUserId': scannerUserId,
        'deviceInfo': await _getDeviceInfo(),
        'location': await _getLocationInfo(),
        'timestamp': FieldValue.serverTimestamp(),
        'scanType': 'qr',
        'additionalData': additionalData ?? {},
      };

      await _firestore.collection('nfc_logs').add(scanData);
      await _updateAnalytics(user.uid, cardId);

      print('QR scan tracked successfully');
    } catch (e) {
      print('Error tracking QR scan: $e');
      rethrow;
    }
  }

  // Get Device Information
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      return {
        'model': androidInfo.model,
        'brand': androidInfo.brand,
        'device': androidInfo.device,
        'os': 'Android ${androidInfo.version.release}',
        'platform': 'Android',
        'userAgent': 'Flutter App',
      };
    } catch (e) {
      return {
        'platform': 'Unknown',
        'error': e.toString(),
      };
    }
  }

  // Get Location Information (Simplified - θα το βελτιώσουμε με GPS)
  Future<Map<String, dynamic>> _getLocationInfo() async {
    // For now, return basic location info
    // TODO: Integrate with GPS plugin for precise location
    return {
      'source': 'estimated',
      'country': 'GR', // Default to Greece
      'city': 'Unknown',
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  // Update User Scan Count
  Future<void> _updateUserScanCount(String userId, int newCount) async {
    await _firestore.collection('users').doc(userId).update({
      'used_scans': newCount,
      'last_scan_date': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // Update Analytics
  Future<void> _updateAnalytics(String userId, String cardId) async {
    final now = DateTime.now();
    final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final analyticsDocId = '${userId}_$dateKey';

    final analyticsRef = _firestore.collection('analytics').doc(analyticsDocId);

    // Use transaction to ensure atomic update
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(analyticsRef);

      if (snapshot.exists) {
        // Update existing analytics
        final currentData = snapshot.data()!;
        final currentScans = currentData['total_scans'] ?? 0;
        final uniqueDevices = currentData['unique_devices'] ?? <String>[];
        final scanTimes = currentData['scan_times'] ?? <String>[];

        // Add current time to scan times
        final timeString = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
        scanTimes.add(timeString);

        transaction.update(analyticsRef, {
          'total_scans': currentScans + 1,
          'scan_times': scanTimes,
          'updated_at': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new analytics document
        final timeString = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

        transaction.set(analyticsRef, {
          'userId': userId,
          'date': dateKey,
          'total_scans': 1,
          'unique_devices': [],
          'scan_times': [timeString],
          'locations': [],
          'card_usage': {cardId: 1},
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // Get User Usage Statistics
  Future<Map<String, dynamic>> getUserUsageStats(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};

      // Get today's analytics
      final now = DateTime.now();
      final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final todayAnalytics = await _firestore.collection('analytics')
          .doc('${userId}_$todayKey')
          .get();

      // Get monthly analytics
      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final monthlyQuery = await _firestore.collection('analytics')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: '$monthKey-01')
          .get();

      int monthlyScans = 0;
      for (final doc in monthlyQuery.docs) {
        monthlyScans += (doc.data()['total_scans'] ?? 0) as int;
      }

      return {
        'subscription_plan': userData['subscription_plan'] ?? 'free',
        'max_scans': userData['max_scans'] ?? 10,
        'used_scans': userData['used_scans'] ?? 0,
        'today_scans': todayAnalytics.data()?['total_scans'] ?? 0,
        'monthly_scans': monthlyScans,
        'scan_limit_reached': (userData['used_scans'] ?? 0) >= (userData['max_scans'] ?? 10),
        'remaining_scans': (userData['max_scans'] ?? 10) - (userData['used_scans'] ?? 0),
      };
    } catch (e) {
      print('Error getting usage stats: $e');
      return {
        'subscription_plan': 'free',
        'max_scans': 10,
        'used_scans': 0,
        'today_scans': 0,
        'monthly_scans': 0,
        'scan_limit_reached': false,
        'remaining_scans': 10,
      };
    }
  }

  // Get Scan History
  Stream<QuerySnapshot> getScanHistory(String userId, {int limit = 50}) {
    return _firestore.collection('nfc_logs')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Get Popular Cards
  Future<List<Map<String, dynamic>>> getPopularCards(String userId) async {
    try {
      final now = DateTime.now();
      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      final analyticsQuery = await _firestore.collection('analytics')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: '$monthKey-01')
          .get();

      final cardUsage = <String, int>{};

      for (final doc in analyticsQuery.docs) {
        final cardData = doc.data()['card_usage'] as Map<String, dynamic>? ?? {};
        cardData.forEach((cardId, count) {
          if (count != null) {
            cardUsage[cardId] = (cardUsage[cardId] ?? 0) + (count as int);
          }
        });
      }

      // Convert to list and sort by usage
      final popularCards = cardUsage.entries
          .map((entry) => {'cardId': entry.key, 'scans': entry.value})
          .toList()
        ..sort((a, b) => (b['scans'] as int).compareTo(a['scans'] as int));

      return popularCards;
    } catch (e) {
      print('Error getting popular cards: $e');
      return [];
    }
  }

  // Reset Monthly Usage (for testing or admin purposes)
  Future<void> resetUsage(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'used_scans': 0,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}