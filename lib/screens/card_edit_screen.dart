import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../models/card_model.dart';

class CardEditScreen extends StatefulWidget {
  final BusinessCard? card; // Null για νέα κάρτα
  final bool isEditing;

  const CardEditScreen({
    super.key,
    this.card,
    this.isEditing = false,
  });

  @override
  State<CardEditScreen> createState() => _CardEditScreenState();
}

class _CardEditScreenState extends State<CardEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  // Social Media Controllers
  final TextEditingController _linkedinController = TextEditingController();
  final TextEditingController _twitterController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();

  bool _isLoading = false;
  bool _isPublic = true;
  List<Map<String, dynamic>> _customActions = [];

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadDefaultActions();
    if (widget.isEditing && widget.card == null) {
      _loadCardFromFirestore();
    }
  }

  void _initializeForm() {
    if (widget.isEditing && widget.card != null) {
      final card = widget.card!;

      _titleController.text = card.title;
      _nameController.text = card.contactInfo['name'] ?? '';
      _emailController.text = card.contactInfo['email'] ?? '';
      _phoneController.text = card.contactInfo['phone'] ?? '';
      _companyController.text = card.contactInfo['company'] ?? '';
      _positionController.text = card.contactInfo['position'] ?? '';
      _websiteController.text = card.contactInfo['website'] ?? '';

      _isPublic = card.isPublic;

      // Social Links
      _linkedinController.text = card.socialLinks['linkedin'] ?? '';
      _twitterController.text = card.socialLinks['twitter'] ?? '';
      _facebookController.text = card.socialLinks['facebook'] ?? '';
      _instagramController.text = card.socialLinks['instagram'] ?? '';

      _customActions = List.from(card.customActions);
    } else {
      // Νέα κάρτα - φόρτωσε δεδομένα από το προφίλ του χρήστη
      _loadUserProfileData();
    }
  }

  Future<void> _loadUserProfileData() async {
    if (_user == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(_user!.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;

        setState(() {
          _nameController.text = userData['name'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _companyController.text = userData['company'] ?? '';
          _positionController.text = userData['position'] ?? '';
          _websiteController.text = userData['website'] ?? '';

          // Social links
          final socialLinks = userData['social_links'] ?? {};
          _linkedinController.text = socialLinks['linkedin'] ?? '';
          _twitterController.text = socialLinks['twitter'] ?? '';
          _facebookController.text = socialLinks['facebook'] ?? '';
          _instagramController.text = socialLinks['instagram'] ?? '';
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  void _loadDefaultActions() {
    if (_customActions.isEmpty) {
      _customActions = [
        {
          'title': 'Κλήση',
          'type': 'phone',
          'value': '',
          'icon': 'call',
          'order': 1,
          'enabled': true,
        },
        {
          'title': 'Email',
          'type': 'email',
          'value': '',
          'icon': 'email',
          'order': 2,
          'enabled': true,
        },
        {
          'title': 'Ιστοσελίδα',
          'type': 'website',
          'value': '',
          'icon': 'language',
          'order': 3,
          'enabled': true,
        },
        {
          'title': 'LinkedIn',
          'type': 'linkedin',
          'value': '',
          'icon': 'person',
          'order': 4,
          'enabled': true,
        },
      ];
    }
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;
    if (_user == null) return;

    setState(() => _isLoading = true);

    try {
      // Update custom actions with current values
      _updateCustomActions();

      final cardData = {
        'ownerId': _user!.uid,
        'title': _titleController.text.trim(),
        'is_active': true,
        'is_public': _isPublic,
        'contact_info': {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'company': _companyController.text.trim(),
          'position': _positionController.text.trim(),
          'website': _websiteController.text.trim(),
        },
        'social_links': {
          'linkedin': _linkedinController.text.trim(),
          'twitter': _twitterController.text.trim(),
          'facebook': _facebookController.text.trim(),
          'instagram': _instagramController.text.trim(),
        },
        'custom_actions': _customActions,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (widget.isEditing && widget.card != null) {
        // Update existing card
        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .collection('cards')
            .doc(widget.card!.cardId).update(cardData);
      } else {
        // Create new card
        cardData['created_at'] = FieldValue.serverTimestamp();
        cardData['qr_code_data'] = 'nexuslink-card-${_user!.uid}-${DateTime.now().millisecondsSinceEpoch}';
        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .collection('cards')
            .add(cardData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              widget.isEditing ? "Η κάρτα ενημερώθηκε!" : "Η κάρτα δημιουργήθηκε!"
          )),
        );
        context.go('/cards'); // Επιστροφή στη λίστα
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Σφάλμα: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateCustomActions() {
    for (var action in _customActions) {
      switch (action['type']) {
        case 'phone':
          action['value'] = _phoneController.text.trim();
          break;
        case 'email':
          action['value'] = _emailController.text.trim();
          break;
        case 'website':
          action['value'] = _websiteController.text.trim();
          break;
        case 'linkedin':
          action['value'] = _linkedinController.text.trim();
          break;
        case 'twitter':
          action['value'] = _twitterController.text.trim();
          break;
        case 'facebook':
          action['value'] = _facebookController.text.trim();
          break;
        case 'instagram':
          action['value'] = _instagramController.text.trim();
          break;
      }
    }
  }

  Future<void> _loadCardFromFirestore() async {
    if (_user == null) return;

    final GoRouterState state = GoRouterState.of(context);
    final String? cardId = state.pathParameters['cardId'];  // <-- Σωστό

    if (cardId == null) return;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('cards')
          .doc(cardId)
          .get();

      if (!doc.exists) return;

      final card = BusinessCard.fromMap(doc.data()!, doc.id);

      setState(() {
        _titleController.text = card.title;
        _nameController.text = card.contactInfo['name'] ?? '';
        _emailController.text = card.contactInfo['email'] ?? '';
        _phoneController.text = card.contactInfo['phone'] ?? '';
        _companyController.text = card.contactInfo['company'] ?? '';
        _positionController.text = card.contactInfo['position'] ?? '';
        _websiteController.text = card.contactInfo['website'] ?? '';
        _isPublic = card.isPublic;
        _customActions = List.from(card.customActions);
      });
    } catch (e) {
      print("Error loading card: $e");
    }
  }




  void _toggleAction(int index) {
    setState(() {
      _customActions[index]['enabled'] = !_customActions[index]['enabled'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? "Επεξεργασία Κάρτας" : "Νέα Κάρτα"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/cards'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveCard,
            tooltip: "Αποθήκευση",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Card Settings
              _buildCardSettings(),
              const SizedBox(height: 25),

              // Contact Information
              _buildSectionTitle("Στοιχεία Επικοινωνίας"),
              _buildTextField(_titleController, "Τίτλος Κάρτας*", Icons.title, isRequired: true),
              _buildTextField(_nameController, "Ονοματεπώνυμο*", Icons.person, isRequired: true),
              _buildTextField(_emailController, "Email*", Icons.email, isRequired: true),
              _buildTextField(_phoneController, "Τηλέφωνο", Icons.phone),
              _buildTextField(_companyController, "Εταιρεία", Icons.business),
              _buildTextField(_positionController, "Θέση Εργασίας", Icons.work),
              _buildTextField(_websiteController, "Ιστοσελίδα", Icons.language),

              const SizedBox(height: 25),

              // Social Media
              _buildSectionTitle("Social Media"),
              _buildTextField(_linkedinController, "LinkedIn URL", Icons.link),
              _buildTextField(_twitterController, "Twitter URL", Icons.link),
              _buildTextField(_facebookController, "Facebook URL", Icons.link),
              _buildTextField(_instagramController, "Instagram URL", Icons.link),

              const SizedBox(height: 25),

              // Quick Actions
              _buildSectionTitle("Γρήγορες Ενέργειες"),
              _buildQuickActions(),

              const SizedBox(height: 30),

              // Save Button
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ρυθμίσεις Κάρτας",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.public, color: Colors.grey.shade600),
                const SizedBox(width: 12),
                const Text("Δημόσια Προβολή"),
                const Spacer(),
                Switch(
                  value: _isPublic,
                  onChanged: (value) => setState(() => _isPublic = value),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            Text(
              _isPublic
                  ? "Η κάρτα σας είναι ορατή σε όλους μέσω NFC/QR"
                  : "Η κάρτα σας είναι ιδιωτική",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
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
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildQuickActions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ..._customActions.asMap().entries.map((entry) {
              final index = entry.key;
              final action = entry.value;

              return Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        _getActionIcon(action['icon']),
                        color: action['enabled']
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          action['title'],
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: action['enabled'] ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                      Switch(
                        value: action['enabled'] ?? true,
                        onChanged: (value) => _toggleAction(index),
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                  if (index < _customActions.length - 1)
                    Divider(color: Colors.grey.shade300),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  IconData _getActionIcon(String iconName) {
    switch (iconName) {
      case 'call': return Icons.call;
      case 'email': return Icons.email;
      case 'language': return Icons.language;
      case 'person': return Icons.person;
      default: return Icons.extension;
    }
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveCard,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
          widget.isEditing ? "ΕΝΗΜΕΡΩΣΗ ΚΑΡΤΑΣ" : "ΔΗΜΙΟΥΡΓΙΑ ΚΑΡΤΑΣ",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _positionController.dispose();
    _websiteController.dispose();
    _linkedinController.dispose();
    _twitterController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    super.dispose();
  }
}