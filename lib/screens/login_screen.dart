import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart'; // ← ΠΡΟΣΘΕΣΕ ΑΥΤΟ

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1) Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      final uid = userCredential.user!.uid;

      // 2) Βρες τι τύπος χρήστη είναι
      final snap = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (!snap.exists) {
        setState(() {
          _error = "Ο λογαριασμός δεν έχει πλήρες προφίλ.";
          _loading = false;
        });
        return;
      }

      // 3) Navigate to home - ΧΡΗΣΗ GoRouter
      if (mounted) {
        context.go('/home'); // ← ΑΛΛΑΓΗ ΕΔΩ
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Δεν βρέθηκε χρήστης με αυτό το email';
          break;
        case 'wrong-password':
          errorMessage = 'Λάθος κωδικός';
          break;
        case 'invalid-email':
          errorMessage = 'Μη έγκυρο email';
          break;
        default:
          errorMessage = e.message ?? 'Σφάλμα σύνδεσης';
      }
      setState(() {
        _error = errorMessage;
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // LOGO
                Image.asset(
                  'assets/logo/nexuslink_logo.png',
                  height: 110,
                ),

                const SizedBox(height: 25),

                Text(
                  "Καλώς Ήρθες",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary, // ← THEME
                  ),
                ),

                const SizedBox(height: 6),
                Text(
                  "Συνέχισε στην εφαρμογή σου",
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                  ),
                ),

                const SizedBox(height: 25),

                // Email
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Password
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Κωδικός",
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 25),

                // LOGIN BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary, // ← THEME
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
                        : const Text(
                      "Σύνδεση",
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Create account - ΧΡΗΣΗ GoRouter
                TextButton(
                  onPressed: _loading ? null : () => context.go('/register'), // ← ΑΛΛΑΓΗ ΕΔΩ
                  child: const Text("Δεν έχεις λογαριασμό; Εγγραφή"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }
}