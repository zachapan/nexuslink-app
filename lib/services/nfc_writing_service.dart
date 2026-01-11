import 'dart:convert';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/card_model.dart';
import 'package:nfc_manager/nfc_manager.dart' as nfc;

class NfcWritingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Έλεγχος αν η συσκευή υποστηρίζει NFC
  Future<bool> isNfcSupported() async {
    try {
      return await NfcManager.instance.isAvailable();
    } catch (e) {
      print('NFC Support Check Error: $e');
      return false;
    }
  }

  /// ============================
  /// ΕΓΓΡΑΦΗ NFC (URL BASED)
  /// ============================
  Future<void> writeCardToNfc({
    required BusinessCard card,
    required Function(String) onStatusUpdate,
    required Function() onSuccess,
    required Function(String) onError,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        onError("Πρέπει να είστε συνδεδεμένοι για NFC εγγραφή");
        return;
      }

      if (!await isNfcSupported()) {
        onError("Η συσκευή σας δεν υποστηρίζει NFC");
        return;
      }

      final cardId = card.cardId;
      if (cardId == null) {
        onError("Μη έγκυρο cardId");
        return;
      }

      final url = "https://nexuslink.app/c/$cardId";

      onStatusUpdate("Πλησιάστε το NFC tag στη συσκευή...");

      await nfc.NfcManager.instance.startSession(
        onDiscovered: (nfc.NfcTag tag) async {
          try {
            onStatusUpdate("Επεξεργασία NFC tag...");

            final ndef = nfc.Ndef.from(tag);
            if (ndef == null) {
              onError("Το NFC tag δεν υποστηρίζει NDEF");
              nfc.NfcManager.instance.stopSession();
              return;
            }

            if (!ndef.isWritable) {
              onError("Το NFC tag δεν είναι εγγράψιμο");
              nfc.NfcManager.instance.stopSession();
              return;
            }

            final message = nfc.NdefMessage([
              nfc.NdefRecord.createUri(Uri.parse(url)),
              nfc.NdefRecord.createText("NexusLink Digital Business Card"),
            ]);

            onStatusUpdate("Γράφω δεδομένα στο NFC tag...");
            await ndef.write(message);

            onStatusUpdate("Επιτυχής εγγραφή! ✅");

            // Firestore updates
            await _updateCardNfcStatus(cardId);
            await _createPublicCardEntry(card);

            onSuccess();
            nfc.NfcManager.instance.stopSession();
          } catch (e) {
            onError("Σφάλμα εγγραφής: $e");
            nfc.NfcManager.instance.stopSession();
          }
        },
      );
    } catch (e) {
      onError("Σφάλμα NFC: $e");
    }
  }

  /// ============================
  /// ΑΝΑΓΝΩΣΗ NFC
  /// ============================
  Future<void> readNfcTag({
    required Function(BusinessCard?) onCardRead,
    required Function(String) onError,
  }) async {
    try {
      if (!await isNfcSupported()) {
        onError("Η συσκευή σας δεν υποστηρίζει NFC");
        return;
      }

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null) {
              onError("Το NFC tag δεν υποστηρίζει NDEF");
              NfcManager.instance.stopSession();
              return;
            }

            final message = ndef.cachedMessage;
            if (message == null || message.records.isEmpty) {
              onError("Άδειο NFC tag");
              NfcManager.instance.stopSession();
              return;
            }

            // Αν είναι URI → redirect logic
            final uriRecord = message.records.firstWhere(
                  (r) => r.type == 'U',
              orElse: () => message.records.first,
            );

            if (uriRecord.type == 'U') {
              final uri = String.fromCharCodes(uriRecord.payload!.sublist(1));
              onError("Link NFC: $uri");
            } else {
              onError("Μη αναγνωρίσιμο NFC περιεχόμενο");
            }

            NfcManager.instance.stopSession();
          } catch (e) {
            onError("Σφάλμα ανάγνωσης: $e");
            NfcManager.instance.stopSession();
          }
        },
      );
    } catch (e) {
      onError("Σφάλμα NFC: $e");
    }
  }

  /// ============================
  /// FIRESTORE HELPERS
  /// ============================
  Future<void> _updateCardNfcStatus(String cardId) async {
    try {
      await _firestore
          .collection("users")
          .doc(_auth.currentUser!.uid)
          .collection("cards")
          .doc(cardId)
          .update({
        "has_nfc": true,
        "updated_at": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Firestore Update Error: $e');
    }
  }

  Future<void> _createPublicCardEntry(BusinessCard card) async {
    try {
      await _firestore.collection("public_cards").doc(card.cardId).set({
        "cardId": card.cardId,
        "ownerId": card.ownerId,
        "title": card.title,
        "contactInfo": card.contactInfo,
        "socialLinks": card.socialLinks,
        "isPublic": card.isPublic,
        "hasNfc": true,
        "createdAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Public Card Entry Error: $e');
    }
  }

  void dispose() {
    NfcManager.instance.stopSession();
  }
}
