import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/nfc_writing_service.dart';
import '../models/card_model.dart';

class NfcWritingScreen extends StatefulWidget {
  final BusinessCard card;

  const NfcWritingScreen({super.key, required this.card});

  @override
  State<NfcWritingScreen> createState() => _NfcWritingScreenState();
}

class _NfcWritingScreenState extends State<NfcWritingScreen> {
  final NfcWritingService _nfcService = NfcWritingService();

  bool _isWriting = false;
  bool _isSupported = true;
  bool _isWritten = false;
  String _statusMessage = 'Έτοιμο για εγγραφή';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkNfcSupport();
  }

  Future<void> _checkNfcSupport() async {
    final supported = await _nfcService.isNfcSupported();
    setState(() => _isSupported = supported);
  }

  Future<void> _writeToNfc() async {
    if (_isWriting) return;

    setState(() {
      _isWriting = true;
      _errorMessage = '';
    });

    await _nfcService.writeCardToNfc(
      card: widget.card,
      onStatusUpdate: (status) {
        setState(() => _statusMessage = status);
      },
      onSuccess: () {
        setState(() {
          _isWriting = false;
          _isWritten = true;
          _statusMessage = 'Εγγραφή ολοκληρώθηκε επιτυχώς!';
        });

        // Επιστροφή μετά από 2 δευτερόλεπτα
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) context.pop(true);
        });
      },
      onError: (error) {
        setState(() {
          _isWriting = false;
          _errorMessage = error;
          _statusMessage = 'Σφάλμα κατά την εγγραφή';
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Share: ${widget.card.title}", // ΝΕΟ: Προσθήκη τίτλου κάρτας
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16, // Λίγο μικρότερο για να χωράει
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white, // ΛΕΥΚΟ ΒΕΛΟΣ
          ),
          onPressed: () => context.pop(),
        ),
        iconTheme: IconThemeData(
          color: Colors.white, // ΛΕΥΚΑ ΟΠΟΙΑΔΗΠΟΤΕ ΑΛΛΑ ΕΙΚΟΝΙΔΙΑ
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (!_isSupported) {
      return _buildNotSupported();
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Card Preview
            _buildCardPreview(),
            const SizedBox(height: 30),

            // Writing Status
            _buildWritingStatus(),
            const SizedBox(height: 20),

            // Action Button
            _buildActionButton(),

            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildErrorWidget(),
            ],

            // Instructions
            const SizedBox(height: 30),
            _buildInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotSupported() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.nfc, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            "Η συσκευή σας δεν υποστηρίζει NFC",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            "Χρειάζεστε συσκευή με NFC και δυνατότητα εγγραφής",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPreview() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.card.title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              widget.card.contactInfo['name'] ?? 'Χωρίς όνομα',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              widget.card.contactInfo['position'] ?? '',
              style: TextStyle(color: Colors.grey),
            ),
            if (_isWritten) ...[
              SizedBox(height: 8),
              Chip(
                label: Text(
                  "ΕΓΓΕΓΡΑΜΜΕΝΟ ΣΕ NFC",
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
                backgroundColor: Colors.green,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWritingStatus() {
    Color statusColor = _isWriting ? Colors.blue :
    _isWritten ? Colors.green : Colors.grey;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        children: [
          Icon(
            _isWriting ? Icons.nfc :
            _isWritten ? Icons.check_circle : Icons.nfc_outlined,
            color: statusColor,
            size: 30,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isWriting ? "Εγγραφή σε εξέλιξη..." :
                  _isWritten ? "Εγγεγραμμένο σε NFC" : "Έτοιμο για εγγραφή",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_statusMessage.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    _statusMessage,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isWriting || _isWritten ? null : _writeToNfc,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white, // ΛΕΥΚΑ ΓΡΑΜΜΑΤΑ ΣΤΟ ΚΟΥΜΠΙ
        ),
        child: _isWriting
            ? SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        )
            : Text(
          _isWritten ? "ΕΓΓΕΓΡΑΜΜΕΝΟ" : "ΕΓΓΡΑΦΗ ΣΕ NFC TAG",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white, // ΕΠΙΠΛΕΟΝ ΛΕΥΚΑ ΓΡΑΜΜΑΤΑ
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red),
          SizedBox(width: 12),
          Expanded(child: Text(_errorMessage)),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Οδηγίες Εγγραφής:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 12),
            _buildInstructionStep(1, "Πατήστε 'ΕΓΓΡΑΦΗ ΣΕ NFC TAG'"),
            _buildInstructionStep(2, "Πλησιάστε το κενό NFC tag στην πίσω πλευρά της συσκευής"),
            _buildInstructionStep(3, "Περιμένετε μέχρι να ολοκληρωθεί η εγγραφή"),
            _buildInstructionStep(4, "Το tag είναι έτοιμο για χρήση!"),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nfcService.dispose();
    super.dispose();
  }
}