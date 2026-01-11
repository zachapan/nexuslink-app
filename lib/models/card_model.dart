import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class BusinessCard {
  String? cardId;
  final String ownerId;
  final String title;
  final bool isActive;
  final bool isPublic;

  final Map<String, dynamic> contactInfo;
  final Map<String, dynamic> socialLinks;
  final List<Map<String, dynamic>> customActions;

  final String? nfcTagId;
  final String qrCodeData;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Νέο field για NFC
  final bool hasNfc;

  BusinessCard({
    this.cardId,
    required this.ownerId,
    required this.title,
    this.isActive = true,
    this.isPublic = true,
    required this.contactInfo,
    required this.socialLinks,
    required this.customActions,
    this.nfcTagId,
    required this.qrCodeData,
    required this.createdAt,
    required this.updatedAt,
    this.hasNfc = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'title': title,
      'is_active': isActive,
      'is_public': isPublic,
      'contact_info': contactInfo,
      'social_links': socialLinks,
      'custom_actions': customActions,
      'nfc_tag_id': nfcTagId,
      'qr_code_data': qrCodeData,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'has_nfc': hasNfc,
    };
  }

  factory BusinessCard.fromMap(Map<String, dynamic> data, String id) {
    return BusinessCard(
      cardId: id,
      ownerId: data['ownerId'] ?? '',
      title: data['title'] ?? 'Untitled Card',
      isActive: data['is_active'] ?? true,
      isPublic: data['is_public'] ?? true,
      contactInfo: Map<String, dynamic>.from(data['contact_info'] ?? {}),
      socialLinks: Map<String, dynamic>.from(data['social_links'] ?? {}),
      customActions: List<Map<String, dynamic>>.from(data['custom_actions'] ?? []),
      nfcTagId: data['nfc_tag_id'],
      qrCodeData: data['qr_code_data'] ?? '',
      createdAt: (data['created_at'] is Timestamp)
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (data['updated_at'] is Timestamp)
          ? (data['updated_at'] as Timestamp).toDate()
          : DateTime.now(),
      hasNfc: data['has_nfc'] ?? false,
    );
  }

  // ΠΡΟΣΘΗΚΗ: Factory από JSON (χωρίς Firestore ID)
  factory BusinessCard.fromJson(Map<String, dynamic> json) {
    return BusinessCard(
      cardId: json['cardId']?.toString(),
      ownerId: json['ownerId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Card',
      isActive: json['isActive'] ?? true,
      isPublic: json['isPublic'] ?? true,
      contactInfo: Map<String, dynamic>.from(json['contactInfo'] ?? {}),
      socialLinks: Map<String, dynamic>.from(json['socialLinks'] ?? {}),
      customActions: List<Map<String, dynamic>>.from(json['customActions'] ?? []),
      nfcTagId: json['nfcTagId']?.toString(),
      qrCodeData: json['qrCodeData']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
      hasNfc: json['hasNfc'] ?? false,
    );
  }

  // ΝΕΟ: Μέθοδος από QR data
  factory BusinessCard.fromQrData(String qrData) {
    try {
      final Map<String, dynamic> data = jsonDecode(qrData);

      // Έλεγχος ότι είναι έγκυρο NexusLink QR
      if (data['type'] != 'nexuslink_business_card') {
        throw const FormatException('Invalid QR data type');
      }

      return BusinessCard(
        cardId: data['cardId']?.toString(),
        ownerId: data['ownerId']?.toString() ?? '',
        title: data['title']?.toString() ?? 'Unknown Card',
        isActive: true,
        isPublic: data['isPublic'] ?? true,
        contactInfo: Map<String, dynamic>.from(data['contactInfo'] ?? {}),
        socialLinks: Map<String, dynamic>.from(data['socialLinks'] ?? {}),
        customActions: List<Map<String, dynamic>>.from(data['customActions'] ?? []),
        nfcTagId: null,
        qrCodeData: qrData,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        hasNfc: false,
      );
    } catch (e) {
      throw FormatException('Invalid QR code data: $e');
    }
  }

  // Βοηθητική μέθοδος για NFC data
  Map<String, dynamic> toNfcData() {
    return {
      'cardId': cardId,
      'ownerId': ownerId,
      'title': title,
      'contactInfo': contactInfo,
      'socialLinks': socialLinks,
      'customActions': customActions,
      'isPublic': isPublic,
      'type': 'business_card',
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
