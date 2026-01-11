import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../screens/pricing_screen.dart';
import '../screens/google_payment_screen.dart';
import '../models/pricing_plan.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _loading = false;
  String _type = "user";
  String _selectedPlan = 'free';
  PricingPlan? _proPlan;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // CREATE ACCOUNT
      final userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
          email: _email.text.trim(), password: _password.text.trim());

      final uid = userCred.user!.uid;

      // SAVE USER IN FIRESTORE με subscription info
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "uid": uid,
        "name": _name.text.trim(),
        "email": _email.text.trim(),
        "type": _type,
        "subscription_plan": _selectedPlan,
        "subscription_status": _type == "user" ? "free" : "pending_payment",
        "max_scans": _type == "user" ? 10 : -1, // -1 για unlimited
        "used_scans": 0,
        "created_at": FieldValue.serverTimestamp(),
        "updated_at": FieldValue.serverTimestamp(),
      });

      // NAVIGATE TO HOME με GoRouter
      if (mounted) {
        if (_type == "pro") {
          // Πήγαινε στο payment screen με το επιλεγμένο plan
          context.go('/google-payment', extra: _proPlan ?? PricingPlan.pro);
        } else {
          // Free user - πήγαινε απευθείας στο home
          context.go('/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Το email χρησιμοποιείται ήδη';
          break;
        case 'weak-password':
          errorMessage = 'Ο κωδικός είναι πολύ αδύναμος';
          break;
        case 'invalid-email':
          errorMessage = 'Μη έγκυρο email';
          break;
        default:
          errorMessage = 'Σφάλμα: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Σφάλμα: ${e.toString()}")),
      );
    }

    setState(() => _loading = false);
  }

  void _showPricingPlans() async {
    final selectedPlan = await showDialog<String>(
      context: context,
      builder: (context) => const PricingScreen(),
    );

    if (selectedPlan != null && mounted) {
      setState(() {
        _type = "pro";
        _selectedPlan = selectedPlan;
        // Βρες το selected plan για να δείξεις τις λεπτομέρειες
        _proPlan = PricingPlan.allPlans.firstWhere(
              (plan) => plan.id == selectedPlan,
          orElse: () => PricingPlan.pro,
        );
      });
    }
  }

  // ΝΕΑ ΜΕΘΟΔΟΣ: Handle register/payment navigation
  void _handleContinue() {
    if (_type == "pro") {
      // Πρώτα κάνε register και μετά πήγαινε στο payment
      _register();
    } else {
      // Free user - κάνε register και πήγαινε στο home
      _register();
    }
  }

  Widget _buildPlanSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Text(
          "Επιλογή Πακέτου:",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        // Free Plan Card
        _buildPlanCard(
          title: "Basic / Free",
          description: "Δωρεάν για τα πρώτα 10 scans",
          price: "10€/έτος μετά",
          features: [
            "1 Ψηφιακή Κάρτα",
            "NFC Sharing",
            "QR Code",
            "Βασικό Προφίλ",
            "10 δωρεάν scans",
          ],
          isSelected: _type == "user",
          onTap: () => setState(() {
            _type = "user";
            _selectedPlan = "free";
            _proPlan = null;
          }),
        ),

        const SizedBox(height: 16),

        // Pro Plan Card
        _buildPlanCard(
          title: "Pro / Business",
          description: "Απεριόριστα scans + Analytics",
          price: _proPlan?.priceText ?? "55€/έτος",
          features: _proPlan?.features.take(5).toList() ?? [
            "5 Ψηφιακές Κάρτες",
            "Απεριόριστα Scans",
            "Στατιστικά & Analytics",
            "Προσαρμοσμένο Branding",
            "Email Marketing",
          ],
          isSelected: _type == "pro",
          onTap: _showPricingPlans,
          isPro: true,
          showArrow: true,
        ),

        // Selected Plan Info
        if (_type == "pro" && _proPlan != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Επιλέξατε: ${_proPlan!.name} - ${_proPlan!.priceText}",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _showPricingPlans,
                  child: const Text("Αλλαγή"),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String description,
    required String price,
    required List<String> features,
    required bool isSelected,
    required VoidCallback onTap,
    bool isPro = false,
    bool showArrow = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.05) : Colors.white,
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showArrow)
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),

            const SizedBox(height: 12),

            // Price
            Text(
              price,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 12),

            // Features
            Column(
              children: features.take(3).map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.check,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),

            if (features.length > 3) ...[
              const SizedBox(height: 8),
              Text(
                "+ ${features.length - 3} ακόμη features...",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Δημιουργία Λογαριασμού"),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(26),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // TITLE
              Text(
                "Δημιουργία Λογαριασμού",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Συμπλήρωσε τα στοιχεία σου και διάλεξε το πακέτο σου",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 30),

              // FULL NAME
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: "Ονοματεπώνυμο*",
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) =>
                val!.isEmpty ? "Εισάγετε ονοματεπώνυμο" : null,
              ),
              const SizedBox(height: 20),

              // EMAIL
              TextFormField(
                controller: _email,
                decoration: InputDecoration(
                  labelText: "Email*",
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) =>
                !val!.contains("@") ? "Μη έγκυρο email" : null,
              ),
              const SizedBox(height: 20),

              // PASSWORD
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Κωδικός*",
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) =>
                val!.length < 6 ? "Ο κωδικός πρέπει να έχει τουλάχιστον 6 χαρακτήρες" : null,
              ),
              const SizedBox(height: 25),

              // PLAN SELECTION
              _buildPlanSelection(),

              const SizedBox(height: 30),

              // REGISTER BUTTON
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                      : Text(
                    _type == "pro" ? "ΣΥΝΕΧΕΙΑ ΣΤΟ ΠΛΗΡΩΜΗ" : "ΔΗΜΙΟΥΡΓΙΑ ΛΟΓΑΡΙΑΣΜΟΥ",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // LOGIN LINK
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Έχεις ήδη λογαριασμό;",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  TextButton(
                    onPressed: _loading ? null : () => context.go('/login'),
                    child: const Text("Σύνδεση"),
                  ),
                ],
              ),

              // Terms Notice
              const SizedBox(height: 20),
              Text(
                "Με την εγγραφή σας, αποδέχεστε τους Όρους Χρήσης και την Πολιτική Απορρήτου",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}