import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/pricing_plan.dart';
import '../services/billing_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class GooglePaymentScreen extends StatefulWidget {
  final PricingPlan plan;

  const GooglePaymentScreen({super.key, required this.plan});

  @override
  State<GooglePaymentScreen> createState() => _GooglePaymentScreenState();
}

class _GooglePaymentScreenState extends State<GooglePaymentScreen> {
  final BillingService _billingService = BillingService();
  bool _isLoading = true;
  bool _isPurchasing = false;
  bool _isSuccess = false;
  String? _errorMessage;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  @override
  void initState() {
    super.initState();
    _initializeBilling();
  }

  Future<void> _initializeBilling() async {
    try {
      await _billingService.initialize();
      _setupPurchaseListener();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = "Δεν είναι διαθέσιμες οι αγορές εφαρμογής: $e";
        _isLoading = false;
      });
    }
  }

  void _setupPurchaseListener() {
    final purchaseStream = _billingService.getPurchaseStream();
    _purchaseSubscription = purchaseStream.listen(_handlePurchaseUpdate);
  }

  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        setState(() {
          _isSuccess = true;
          _isPurchasing = false;
        });
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        setState(() {
          _errorMessage = "Η αγορά απέτυχε. Δοκιμάστε ξανά.";
          _isPurchasing = false;
        });
      } else if (purchaseDetails.status == PurchaseStatus.pending) {
        setState(() => _isPurchasing = true);
      }
    }
  }

  // ΝΕΑ ΜΕΘΟΔΟΣ: Back navigation
  void _goBack() {
    // Χρησιμοποίησε GoRouter για να πάς πίσω
    if (context.canPop()) {
      context.pop(); // Πήγαινε πίσω στην προηγούμενη οθόνη
    } else {
      // Fallback: Πήγαινε στο register screen
      context.go('/register');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ολοκλήρωση Αγοράς"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: _isPurchasing
            ? null // Απενεργοποίηση κατά τη διάρκεια αγοράς
            : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack, // ← ΧΡΗΣΗ ΤΗΣ ΝΕΑΣ ΜΕΘΟΔΟΥ
          tooltip: "Πίσω",
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _isSuccess
          ? _buildSuccessState()
          : _buildPaymentUI(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text("Φόρτωση..."),
        ],
      ),
    );
  }

  Widget _buildPaymentUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildOrderSummary(),
          const SizedBox(height: 30),
          _buildGooglePlayInfo(),
          const SizedBox(height: 30),
          _buildPurchaseButton(),
          if (_errorMessage != null) ...[
            const SizedBox(height: 20),
            _buildErrorWidget(),
          ],
          // Back button alternative
          const SizedBox(height: 20),
          _buildAlternativeBackButton(),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.workspace_premium,
                  color: Theme.of(context).colorScheme.primary,
                  size: 30,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.plan.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.plan.description,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  widget.plan.priceText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Divider(),
            const SizedBox(height: 10),
            ...widget.plan.features.take(3).map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
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

  Widget _buildGooglePlayInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.shop,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Ασφαλής Πληρωμή μέσω Google Play",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Η πληρωμή θα χρεωθεί στο Google Play λογαριασμό σας",
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
      ),
    );
  }

  Widget _buildPurchaseButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isPurchasing ? null : _purchaseProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isPurchasing
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.shop,
                color: Colors.green,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "ΑΓΟΡΑ ΜΕΣΩ GOOGLE PLAY",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  // ΝΕΟ: Alternative back button στο body
  Widget _buildAlternativeBackButton() {
    return TextButton(
      onPressed: _goBack,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.arrow_back, size: 16),
          SizedBox(width: 8),
          Text("Πίσω στην Εγγραφή"),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green.shade600,
              size: 80,
            ),
            const SizedBox(height: 30),
            Text(
              "Η Αγορά Ολοκληρώθηκε!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              "Το πακέτο ${widget.plan.name} ενεργοποιήθηκε επιτυχώς",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "ΣΥΝΕΧΕΙΑ ΣΤΟ HOME",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchaseProduct() async {
    setState(() {
      _isPurchasing = true;
      _errorMessage = null;
    });

    try {
      final productId = _getProductIdForPlan(widget.plan.id);
      await _billingService.purchaseProduct(productId);
    } catch (e) {
      setState(() {
        _errorMessage = "Σφάλμα κατά την αγορά: $e";
        _isPurchasing = false;
      });
    }
  }

  String _getProductIdForPlan(String planId) {
    switch (planId) {
      case 'basic': return 'nexuslink_basic_yearly';
      case 'pro': return 'nexuslink_pro_yearly';
      case 'enterprise': return 'nexuslink_enterprise_yearly';
      default: return 'nexuslink_pro_yearly';
    }
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    _billingService.dispose();
    super.dispose();
  }
}