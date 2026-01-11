import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../services/usage_tracking_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final UsageTrackingService _usageService = UsageTrackingService();
  final User? _user = FirebaseAuth.instance.currentUser;

  Map<String, dynamic> _usageStats = {};
  List<Map<String, dynamic>> _popularCards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    if (_user == null) return;

    try {
      final stats = await _usageService.getUserUsageStats(_user!.uid);
      final popularCards = await _usageService.getPopularCards(_user!.uid);

      setState(() {
        _usageStats = stats;
        _popularCards = popularCards;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Στατιστικά & Analytics",
          style: TextStyle(
          color: Colors.white,
            fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        ),

        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: Colors.white,
            onPressed: _loadAnalytics,
            tooltip: "Ανανέωση",
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _buildAnalyticsContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text("Φόρτωση στατιστικών..."),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Usage Summary
            _buildUsageSummary(),
            const SizedBox(height: 20),

            // Popular Cards
            _buildPopularCards(),

            // Scan History
            _buildScanHistory(),

            // Upgrade Prompt if needed
            if (_usageStats['scan_limit_reached'] == true) ...[
              const SizedBox(height: 20),
              _buildUpgradePrompt(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsageSummary() {
    final remainingScans = _usageStats['remaining_scans'] ?? 0;
    final maxScans = _usageStats['max_scans'] ?? 10;
    final usedScans = _usageStats['used_scans'] ?? 0;
    final progress = usedScans / maxScans;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Πλήθος Scans",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Chip(
                  label: Text(
                    _usageStats['subscription_plan'] == 'free' ? 'FREE' : 'PRO',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: _usageStats['subscription_plan'] == 'free'
                      ? Colors.orange
                      : Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Progress Bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1 ? Colors.red : Theme.of(context).colorScheme.primary,
              ),
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 10),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem("Χρησιμοποιημένα", "$usedScans", Icons.touch_app),
                _buildStatItem("Διαθέσιμα", "$remainingScans", Icons.all_inclusive),
                _buildStatItem("Σήμερα", "${_usageStats['today_scans']}", Icons.today),
                _buildStatItem("Μήνας", "${_usageStats['monthly_scans']}", Icons.calendar_today),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPopularCards() {
    if (_popularCards.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.credit_card,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 10),
              const Text(
                "Δεν υπάρχουν δεδομένα χρήσης ακόμη",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Δημοφιλείς Κάρτες",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            ..._popularCards.take(5).map((card) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.credit_card,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Κάρτα ${card['cardId']?.substring(0, 8) ?? 'Unknown'}",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          "${card['scans']?.toString() ?? '0'} scans",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildScanHistory() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ιστορικό Scans",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: _usageService.getScanHistory(_user!.uid, limit: 10),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // Καλύτερο error handling
                  final error = snapshot.error;
                  if (error is FirebaseException && error.code == 'permission-denied') {
                    return _buildPermissionError();
                  }
                  return Text('Σφάλμα: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final scans = snapshot.data!.docs;

                if (scans.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      "Δεν υπάρχουν καταγεγραμμένα scans",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return Column(
                  children: scans.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final timestamp = data['timestamp'] as Timestamp?;
                    final deviceInfo = data['deviceInfo'] as Map<String, dynamic>? ?? {};

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          data['scanType'] == 'nfc' ? Icons.nfc : Icons.qr_code,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          "${deviceInfo['model'] ?? 'Unknown Device'}",
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          timestamp != null
                              ? _formatTimestamp(timestamp)
                              : 'Unknown time',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        trailing: Chip(
                          label: Text(
                            data['scanType']?.toString().toUpperCase() ?? 'NFC',
                            style: const TextStyle(fontSize: 10, color: Colors.white),
                          ),
                          backgroundColor: data['scanType'] == 'nfc'
                              ? Colors.blue
                              : Colors.green,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

// Νέο method για permission error
  Widget _buildPermissionError() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.security, color: Colors.orange.shade600, size: 40),
          const SizedBox(height: 10),
          const Text(
            "Δεν υπάρχει πρόσβαση στα δεδομένα",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            "Ελέγξτε τα Firestore Rules ή προσπαθήστε ξανά αργότερα",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradePrompt() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Φτάσατε το όριο scans!",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Αναβαθμίστε σε Pro για απεριόριστα scans",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.go('/pricing'),
            child: Text(
              "ΑΝΑΒΑΘΜΙΣΗ",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
