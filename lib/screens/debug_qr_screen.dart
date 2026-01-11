// debug_qr_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';

class DebugQrScreen extends StatelessWidget {
  final String qrData;

  const DebugQrScreen({super.key, required this.qrData});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? parsedData;

    try {
      parsedData = jsonDecode(qrData);
    } catch (e) {
      parsedData = {'error': e.toString()};
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Debug QR Data")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Raw QR Data:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.grey[200],
              child: SelectableText(qrData),
            ),
            const SizedBox(height: 30),
            const Text(
              "Parsed JSON:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.grey[200],
              child: SelectableText(
                const JsonEncoder.withIndent('  ').convert(parsedData),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (parsedData?['type'] == 'nexuslink_business_card') {
                  Navigator.pop(context);
                  // Επιστροφή στο σκανάρισμα
                }
              },
              child: const Text("Επιστροφή"),
            ),
          ],
        ),
      ),
    );
  }
}