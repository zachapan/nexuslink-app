import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class BillingService {
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];

  // Product IDs - πρέπει να ταιριάζουν με Google Play Console
  static final Map<String, String> _productIds = {
    'free': 'free_plan',
    'basic': 'nexuslink_basic_yearly',
    'pro': 'nexuslink_pro_yearly',
    'enterprise': 'nexuslink_enterprise_yearly',
  };

  Future<void> initialize() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      throw Exception('In-app purchases not available');
    }

    // Listen to purchase updates
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _handlePurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => print('Purchase error: $error'),
    );

    // Load products
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    final Set<String> productIds = Set<String>.from(_productIds.values);
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);

    if (response.notFoundIDs.isNotEmpty) {
      print('Products not found: ${response.notFoundIDs}');
    }

    _products = response.productDetails;
  }

  List<ProductDetails> getAvailableProducts() {
    return _products;
  }

  ProductDetails getProductById(String productId) {
    return _products.firstWhere(
          (product) => product.id == productId,
      orElse: () => throw Exception('Product not found: $productId'),
    );
  }

  Future<void> purchaseProduct(String productId) async {
    try {
      final product = getProductById(productId);

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      // For consumable products (one-time purchases)
      await _inAppPurchase.buyConsumable(
        purchaseParam: purchaseParam,
        autoConsume: true,
      );
    } catch (e) {
      print('Purchase failed: $e');
      rethrow;
    }
  }

  Future<void> _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Purchase is pending
        await _handlePendingPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.purchased) {
        // Purchase completed successfully
        await _handleSuccessfulPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Purchase failed
        await _handleFailedPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.restored) {
        // Purchase restored
        await _handleRestoredPurchase(purchaseDetails);
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> _handlePendingPurchase(PurchaseDetails purchaseDetails) async {
    // Update UI - show loading state
    print('Purchase pending: ${purchaseDetails.productID}');
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    if (_user == null) return;

    try {
      // Verify purchase with your server (optional but recommended)
      await _verifyPurchase(purchaseDetails);

      // Update user subscription in Firestore
      final planId = _getPlanIdFromProductId(purchaseDetails.productID);

      await _firestore.collection('users').doc(_user!.uid).update({
        'type': 'pro',
        'subscription_plan': planId,
        'subscription_status': 'active',
        'purchase_token': purchaseDetails.purchaseID ?? '',
        'subscription_start_date': FieldValue.serverTimestamp(),
        'subscription_end_date': _calculateEndDate(),
        'max_scans': -1, // Unlimited for paid plans
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('Purchase successful: ${purchaseDetails.productID}');
    } catch (e) {
      print('Error handling purchase: $e');
    }
  }

  Future<void> _handleFailedPurchase(PurchaseDetails purchaseDetails) async {
    print('Purchase failed: ${purchaseDetails.error}');
    // Show error message to user
  }

  Future<void> _handleRestoredPurchase(PurchaseDetails purchaseDetails) async {
    print('Purchase restored: ${purchaseDetails.productID}');
    await _handleSuccessfulPurchase(purchaseDetails);
  }

  Future<void> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // For production, verify purchase with your backend
    // This prevents fraud

    if (purchaseDetails is GooglePlayPurchaseDetails) {
      // Verify with Google Play API
      final String? purchaseToken = purchaseDetails.purchaseID;
      final String productId = purchaseDetails.productID;

      if (purchaseToken != null) {
        // Call your verification endpoint
        await _verifyWithBackend(purchaseToken, productId);
      }
    }
  }

  // Προσθέστε αυτή τη μέθοδο στο BillingService class
  Stream<List<PurchaseDetails>> getPurchaseStream() {
    return _inAppPurchase.purchaseStream;
  }

  Future<void> _verifyWithBackend(String purchaseToken, String productId) async {
    try {
      // Implement server-side verification
      // This is crucial for security
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('verifyPurchase');

      await callable.call({
        'purchaseToken': purchaseToken,
        'productId': productId,
      });
    } catch (e) {
      print('Verification error: $e');
      // Continue anyway for demo purposes
    }
  }

  String _getPlanIdFromProductId(String productId) {
    return _productIds.entries.firstWhere(
          (entry) => entry.value == productId,
      orElse: () => MapEntry('pro', 'pro'),
    ).key;
  }

  DateTime _calculateEndDate() {
    // Add 1 year to current date
    return DateTime.now().add(const Duration(days: 365));
  }

  Future<void> checkExistingSubscription() async {
    if (_user == null) return;

    // For non-consumable products, check past purchases
    try {
      // In the new API, we listen to the purchase stream for restored purchases
      // You might want to implement a server-side check for active subscriptions
      print('Checking existing subscriptions...');
    } catch (e) {
      print('Error checking subscriptions: $e');
    }
  }

  // New method to restore purchases
  Future<void> restorePurchases() async {
    try {
      // In the new API, purchases are automatically restored
      // when you listen to the purchase stream
      print('Restoring purchases...');

      // You can also query past purchases (if supported)
      // Note: This might not be available in all versions
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      print('Error restoring purchases: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}