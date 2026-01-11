import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();
  final TextEditingController _twitterController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();

  // Password controller for account deletion
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = true;
  bool _isEditing = false;
  String? _userType;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _uid = user.uid;

    try {
      final doc = await _firestore.collection('users').doc(_uid).get();

      if (doc.exists && mounted) {
        final data = doc.data()!;

        setState(() {
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _companyController.text = data['company'] ?? '';
          _positionController.text = data['position'] ?? '';
          _websiteController.text = data['website'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _locationController.text = data['location'] ?? '';
          _userType = data['type'] ?? 'user';

          // Social links
          final socialLinks = data['social_links'] ?? {};
          _linkedinController.text = socialLinks['linkedin'] ?? '';
          _twitterController.text = socialLinks['twitter'] ?? '';
          _facebookController.text = socialLinks['facebook'] ?? '';

          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading profile: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_uid == null) return;

    try {
      final userData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'company': _companyController.text.trim(),
        'position': _positionController.text.trim(),
        'website': _websiteController.text.trim(),
        'bio': _bioController.text.trim(),
        'location': _locationController.text.trim(),
        'social_links': {
          'linkedin': _linkedinController.text.trim(),
          'twitter': _twitterController.text.trim(),
          'facebook': _facebookController.text.trim(),
        },
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(_uid!).set(
        userData,
        SetOptions(merge: true),
      );

      // Επιστροφή σε view mode
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Το προφίλ ενημερώθηκε επιτυχώς!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Σφάλμα αποθήκευσης: $e")),
        );
      }
    }
  }

  void _toggleEdit() {
    setState(() => _isEditing = !_isEditing);
  }

  void _cancelEdit() {
    _loadUserProfile(); // Reload original data
    setState(() => _isEditing = false);
  }

  // ΝΕΟ: Onboarding Settings
  Widget _buildOnboardingSetting() {
    return FutureBuilder<bool>(
      future: _getOnboardingPreference(),
      builder: (context, snapshot) {
        final skipOnboarding = snapshot.data ?? false;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Εμφάνιση Onboarding",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Εμφάνιση οδηγιών χρήσης κατά την εκκίνηση",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: !skipOnboarding, // Αντιστροφή λογικής για το switch
                  onChanged: (value) async {
                    await _setOnboardingPreference(!value);
                    // Επανάληψη του FutureBuilder
                    if (mounted) {
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              value
                                  ? "Το onboarding θα εμφανίζεται στην επόμενη εκκίνηση"
                                  : "Το onboarding δεν θα εμφανίζεται ξανά"
                          ),
                        ),
                      );
                    }
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _getOnboardingPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('skip_onboarding') ?? false;
  }

  Future<void> _setOnboardingPreference(bool skip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('skip_onboarding', skip);
  }

  // ΝΕΟ: Διαγραφή Λογαριασμού
  Widget _buildDeleteAccountSection() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Διαγραφή Λογαριασμού",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Η διαγραφή του λογαριασμού σας είναι μόνιμη και αμετάκλητη. Θα διαγραφούν όλα τα δεδομένα σας.",
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _showDeleteAccountDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.shade400),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text("Διαγραφή Λογαριασμού"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Διαγραφή Λογαριασμού"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Αυτή η ενέργεια είναι μόνιμη και αμετάκλητη."),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Εισάγετε τον κωδικό σας για επιβεβαίωση",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Ακύρωση"),
          ),
          TextButton(
            onPressed: _deleteAccount,
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text("Διαγραφή"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null || _passwordController.text.isEmpty) return;

    try {
      // 1. Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      // 2. Delete user data from Firestore
      await _deleteUserData(user.uid);

      // 3. Delete user from Authentication
      await user.delete();

      // 4. Navigate to login screen
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ο λογαριασμός διαγράφηκε επιτυχώς")),
        );
        context.go('/login');
      }

    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop(); // Close dialog
      String errorMessage = "Σφάλμα διαγραφής: ";

      if (e.code == 'wrong-password') {
        errorMessage += "Λάθος κωδικός πρόσβασης";
      } else if (e.code == 'requires-recent-login') {
        errorMessage += "Απαιτείται πρόσφατη σύνδεση. Παρακαλώ συνδεθείτε ξανά.";
      } else {
        errorMessage += e.message ?? "Άγνωστο σφάλμα";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Σφάλμα διαγραφής: $e")),
        );
      }
    }
  }

  Future<void> _deleteUserData(String userId) async {
    try {
      // Delete user document
      await _firestore.collection('users').doc(userId).delete();

      // Delete user's cards subcollection
      final cardsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cards')
          .get();

      final batch = _firestore.batch();
      for (final doc in cardsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete user's data from public_cards
      final publicCardsSnapshot = await _firestore
          .collection('public_cards')
          .where('ownerId', isEqualTo: userId)
          .get();

      final publicBatch = _firestore.batch();
      for (final doc in publicCardsSnapshot.docs) {
        publicBatch.delete(doc.reference);
      }
      await publicBatch.commit();

      print("User data deleted successfully");
    } catch (e) {
      print("Error deleting user data: $e");
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Προφίλ")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Προφίλ Χρήστη",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => context.go('/home'),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              color: Colors.white,
              onPressed: _toggleEdit,
              tooltip: "Επεξεργασία Προφίλ",
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Header
              _buildProfileHeader(),
              const SizedBox(height: 30),

              // Personal Information
              _buildSectionTitle("Προσωπικές Πληροφορίες"),
              _buildTextField(_nameController, "Ονοματεπώνυμο", Icons.person, isRequired: true),
              _buildTextField(_emailController, "Email", Icons.email, enabled: false),
              _buildTextField(_phoneController, "Τηλέφωνο", Icons.phone),
              _buildTextField(_locationController, "Τοποθεσία", Icons.location_on),

              const SizedBox(height: 25),

              // Professional Information
              _buildSectionTitle("Επαγγελματικές Πληροφορίες"),
              _buildTextField(_companyController, "Εταιρεία", Icons.business),
              _buildTextField(_positionController, "Θέση Εργασίας", Icons.work),
              _buildTextField(_websiteController, "Ιστοσελίδα", Icons.language),
              _buildTextField(_bioController, "Σύντομο Βιογραφικό", Icons.description, maxLines: 3),

              const SizedBox(height: 25),

              // Social Media
              _buildSectionTitle("Social Media"),
              _buildTextField(_linkedinController, "LinkedIn URL", Icons.link),
              _buildTextField(_twitterController, "Twitter URL", Icons.link),
              _buildTextField(_facebookController, "Facebook URL", Icons.link),

              const SizedBox(height: 30),

              // Edit/Save Buttons
              if (_isEditing) _buildActionButtons(),

              const SizedBox(height: 30),

              // Onboarding Settings
              _buildOnboardingSetting(),

              const SizedBox(height: 20),

              // Delete Account Section
              _buildDeleteAccountSection(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue.shade100,
              child: Icon(
                Icons.person,
                size: 50,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nameController.text.isNotEmpty ? _nameController.text : "Χωρίς Όνομα",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _positionController.text.isNotEmpty
                        ? _positionController.text
                        : "Δεν έχει οριστεί θέση",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Chip(
                    label: Text(
                      _userType == "pro" ? "PRO Account" : "Basic Account",
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                    backgroundColor: _userType == "pro"
                        ? Colors.deepOrange
                        : Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        bool isRequired = false,
        bool enabled = true,
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: _isEditing && enabled,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: !_isEditing,
          fillColor: !_isEditing ? Colors.grey.shade50 : null,
        ),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'Αυτό το πεδίο είναι απαραίτητο';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _cancelEdit,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Ακύρωση"),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Αποθήκευση",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _positionController.dispose();
    _websiteController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _linkedinController.dispose();
    _twitterController.dispose();
    _facebookController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}