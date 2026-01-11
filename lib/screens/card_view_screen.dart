import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/card_model.dart';

class CardViewScreen extends StatelessWidget {
  final BusinessCard card;

  const CardViewScreen({super.key, required this.card});

  void _launchAction(BuildContext context, String type, String value) async {
    try {
      final Uri uri;
      switch (type) {
        case 'phone':
          uri = Uri.parse('tel:$value');
          break;
        case 'email':
          uri = Uri.parse('mailto:$value');
          break;
        case 'website':
          uri = Uri.parse(value.startsWith('http') ? value : 'https://$value');
          break;
        case 'sms':
          uri = Uri.parse('sms:$value');
          break;
        case 'linkedin':
          uri = Uri.parse(value.startsWith('http') ? value : 'https://linkedin.com/in/$value');
          break;
        case 'twitter':
          uri = Uri.parse(value.startsWith('http') ? value : 'https://twitter.com/$value');
          break;
        case 'facebook':
          uri = Uri.parse(value.startsWith('http') ? value : 'https://facebook.com/$value');
          break;
        case 'instagram':
          uri = Uri.parse(value.startsWith('http') ? value : 'https://instagram.com/$value');
          break;
        default:
          return;
      }

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Δεν μπορώ να ανοίξω: $value")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Σφάλμα: $e")),
      );
    }
  }

  String _getContactValue(String key) {
    final value = card.contactInfo[key];
    if (value == null || (value is String && value.isEmpty)) return "-";
    return value.toString();
  }

  String _getActionValue(Map<String, dynamic> action) {
    final value = action['value'];
    if (value == null || (value is String && value.isEmpty)) return "-";
    return value.toString();
  }

  String _getSocialValue(String key, dynamic value) {
    if (value == null || (value is String && value.isEmpty)) return "-";
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text(
          "Επαγγελματική Κάρτα",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey[900],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => _shareCard(context),
            tooltip: "Κοινοποίηση",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[800]!, Colors.grey[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar + Name
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.blue.shade700,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  _getContactValue('name'),
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                Text(
                  _getContactValue('position'),
                  style: TextStyle(fontSize: 16, color: Colors.blue[100]),
                  textAlign: TextAlign.center,
                ),
                Text(
                  _getContactValue('company'),
                  style: TextStyle(fontSize: 14, color: Colors.blue[200]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Contact Info
                _buildSectionTitle("Στοιχεία Επικοινωνίας"),
                const SizedBox(height: 12),
                _buildInfoTile(context, Icons.phone, _getContactValue('phone'), 'phone'),
                _buildInfoTile(context, Icons.email, _getContactValue('email'), 'email'),
                _buildInfoTile(context, Icons.language, _getContactValue('website'), 'website'),
                const SizedBox(height: 20),

                // Custom Actions
                if (card.customActions.isNotEmpty) ...[
                  _buildSectionTitle("Γρήγορες Ενέργειες"),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: card.customActions
                        .where((a) => a['enabled'] == true)
                        .map((action) {
                      final value = _getActionValue(action);
                      return ActionChip(
                        avatar: Icon(
                          _getActionIcon(action['type']),
                          size: 18,
                          color: Colors.blueGrey[900],
                        ),
                        label: Text(action['title'] ?? "-"),
                        backgroundColor: Colors.blue[100],
                        onPressed: value != "-" ? () => _launchAction(context, action['type'], value) : null,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Social Links
                if (card.socialLinks.isNotEmpty) ...[
                  _buildSectionTitle("Social Media"),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: card.socialLinks.entries.map((e) {
                      final value = _getSocialValue(e.key, e.value);
                      return ActionChip(
                        avatar: Icon(_getSocialIcon(e.key), size: 18, color: Colors.blueGrey[900]),
                        label: Text(e.key.capitalize()),
                        backgroundColor: Colors.blue[100],
                        onPressed: value != "-" ? () => _launchAction(context, e.key, value) : null,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Company Info
                _buildSectionTitle("Πληροφορίες Εταιρείας"),
                const SizedBox(height: 12),
                _buildInfoRow('Εταιρεία', _getContactValue('company')),
                _buildInfoRow('Θέση', _getContactValue('position')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _buildInfoTile(BuildContext context, IconData icon, String value, String type) {
    return Card(
      color: Colors.grey[400],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueGrey[900]),
        title: Text(
          value,
          style: const TextStyle(color: Colors.white),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
        onTap: value != "-" ? () => _launchAction(context, type, value) : null,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(String type) {
    switch (type) {
      case 'phone':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'website':
        return Icons.language;
      case 'sms':
        return Icons.message;
      case 'location':
        return Icons.location_on;
      case 'vcard':
        return Icons.contact_page;
      default:
        return Icons.touch_app;
    }
  }

  IconData _getSocialIcon(String type) {
    switch (type) {
      case 'linkedin':
        return Icons.work;
      case 'twitter':
        return Icons.chat;
      case 'facebook':
        return Icons.thumb_up;
      case 'instagram':
        return Icons.camera_alt;
      default:
        return Icons.link;
    }
  }

  void _shareCard(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Κοινοποίηση κάρτας..."),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// Extension για κεφαλαίο πρώτο γράμμα
extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return '';
    return this[0].toUpperCase() + substring(1);
  }
}
