import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/card_model.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = true;
  bool _isTorchOn = false;
  bool _isFrontCamera = false;
  bool _showSuccess = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Σάρωση QR Code",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Flash/Torch toggle
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: _toggleTorch,
            tooltip: "Φλας",
          ),
          // Switch camera
          IconButton(
            icon: const Icon(
              Icons.cameraswitch,
              color: Colors.white,
            ),
            onPressed: _switchCamera,
            tooltip: "Αλλαγή κάμερας",
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (!_isScanning) return;

              final List<Barcode> barcodes = capture.barcodes;

              if (barcodes.isNotEmpty) {
                _isScanning = false;
                final String? qrData = barcodes.first.rawValue;

                if (qrData != null) {
                  _playScanFeedback();
                  _processQrData(qrData);
                }
              }
            },
          ),

          // Success overlay
          if (_showSuccess) _buildSuccessOverlay(),

          // Overlay
          _buildScannerOverlay(),

          // Instructions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildInstructions(),
          ),
        ],
      ),
    );
  }

  void _playScanFeedback() {
    // 1. Κραδασμός (Haptic feedback)
    HapticFeedback.mediumImpact();

    // 2. Ήχος (System sound)
    SystemSound.play(SystemSoundType.click);

    // 3. Visual feedback
    setState(() {
      _showSuccess = true;
    });

    // Αφαίρεση μετά από 1 δευτερόλεπτο
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showSuccess = false;
        });
      }
    });
  }

  Widget _buildSuccessOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 20),
            Text(
              "QR Code Βρέθηκε!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Επεξεργασία...",
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Scanning area
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.green,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 30),
          // Scanning animation
          if (_isScanning)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner, color: Colors.green.shade300),
                  const SizedBox(width: 10),
                  const Text(
                    "Σάρωση σε εξέλιξη...",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanningAnimation() {
    return Stack(
      children: [
        // Scanning line
        AnimatedContainer(
          duration: const Duration(seconds: 2),
          margin: EdgeInsets.only(top: _isScanning ? 0 : 250),
          curve: Curves.linear,
          child: Container(
            height: 2,
            color: Colors.green,
            width: 250,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.9),
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            "Οδηγίες Σκανάρισματος",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "• Τοποθετήστε το QR Code μέσα στο πλαίσιο\n"
                "• Περιμένετε μέχρι να εντοπιστεί αυτόματα\n"
                "• Χρησιμοποιήστε το φλας σε χαμηλό φωτισμό",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _toggleTorch() {
    setState(() {
      _isTorchOn = !_isTorchOn;
    });
    cameraController.toggleTorch();
  }

  void _switchCamera() {
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
    cameraController.switchCamera();
  }

  void _processQrData(String qrData) {
    // Προσθήκη ήχου και κραδασμού όταν βρίσκει QR
    _playSuccessFeedback();

    try {
      // 1. Προσπαθήστε να διαβάσετε ως NexusLink QR
      try {
        final Map<String, dynamic> jsonData = jsonDecode(qrData);

        if (jsonData['type'] == 'nexuslink_business_card') {
          // Είναι NexusLink QR
          final BusinessCard card = BusinessCard.fromQrData(qrData);
          _openCardView(card);
          return;
        }
      } catch (e) {
        // Δεν είναι JSON, προχωράμε στο επόμενο βήμα
      }

      // 2. Έλεγχος αν είναι URL
      if (qrData.startsWith('http://') || qrData.startsWith('https://')) {
        _showUrlDialog(qrData);
        return;
      }

      // 3. Έλεγχος αν είναι vCard
      if (qrData.contains('BEGIN:VCARD')) {
        _showVCardDialog(qrData);
        return;
      }

      // 4. Γενικό περιεχόμενο
      _showGenericContentDialog(qrData);

    } catch (e) {
      print("Error processing QR: $e");
      _showErrorDialog("Σφάλμα επεξεργασίας: $e");
    }
  }

  void _openCardView(BusinessCard card) {
    // Κλείσιμο scanner
    cameraController.stop();

    // Μικρή καθυστέρηση για καλύτερη UX
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.pop(); // Κλείσιμο scanner screen
        context.push('/card-view', extra: card);
      }
    });
  }

  void _showUrlDialog(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("URL Βρέθηκε"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Το QR περιέχει έναν σύνδεσμο:"),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.grey[200],
              child: SelectableText(
                url,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Ακύρωση"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
            child: const Text("Άνοιγμα"),
          ),
        ],
      ),
    ).then((value) {
      _resetScanner();
    });
  }

  void _showVCardDialog(String vCardData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Επαφή vCard"),
        content: const Text("Το QR περιέχει επαφή vCard. Θέλετε να την αποθηκεύσετε;"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Όχι"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Εδώ θα προσθέσετε κώδικα για αποθήκευση vCard
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Αποθήκευση επαφής...")),
              );
            },
            child: const Text("Αποθήκευση"),
          ),
        ],
      ),
    ).then((value) {
      _resetScanner();
    });
  }

  void _showGenericContentDialog(String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Περιεχόμενο QR"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Το QR περιέχει:"),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.grey[200],
                child: SelectableText(
                  content,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScanner();
            },
            child: const Text("OK"),
          ),
          // Κουμπί αντιγραφής
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: "Αντιγραφή",
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Αντιγράφηκε στο clipboard")),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Σφάλμα"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetScanner();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _resetScanner() {
    setState(() {
      _isScanning = true;
    });
    cameraController.start();
  }

  void _playSuccessFeedback() async {
    // Κραδασμός (vibration)
    // Χρειάζεται: import 'package:vibration/vibration.dart';
    // και στο pubspec.yaml: vibration: ^1.8.0

    // Ήχος (beep)
    // Χρειάζεται: import 'package:audioplayers/audioplayers.dart';

    // Προσωρινά, μόνο visual feedback
    setState(() {
      _isScanning = false;
    });
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}