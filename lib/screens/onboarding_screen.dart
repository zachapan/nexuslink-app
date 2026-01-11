import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  bool _skipOnboarding = false; // Νέο state για το checkbox

  final List<_OnboardData> pages = [
    _OnboardData(
      title: "Digital Business Card",
      subtitle: "Μοιράσου άμεσα τα στοιχεία σου με NFC ή QR – χωρίς φυσική κάρτα.",
      icon: Icons.nfc_rounded,
    ),
    _OnboardData(
      title: "Smart Actions",
      subtitle: "Call, SMS, Email, Social Links, Custom profile actions και πολλά άλλα.",
      icon: Icons.bolt_rounded,
    ),
    _OnboardData(
      title: "Cloud Sync",
      subtitle: "Τα στοιχεία σου αποθηκεύονται με ασφάλεια στο cloud μέσω Firebase.",
      icon: Icons.cloud_sync_rounded,
    ),
    _OnboardData(
      title: "Analytics & Insights",
      subtitle: "Δες πόσοι είδαν την κάρτα σου, τοποθεσίες, devices, και πολλά άλλα.",
      icon: Icons.bar_chart_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  // Έλεγχος αν ο χρήστης έχει επιλέξει να skip το onboarding
  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final shouldSkip = prefs.getBool('skip_onboarding') ?? false;

    if (shouldSkip && mounted) {
      context.go('/login');
    }
  }

  // Αποθήκευση της προτίμησης του χρήστη
  Future<void> _saveOnboardingPreference(bool skip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('skip_onboarding', skip);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            //
            // PAGE VIEW
            //
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          page.icon,
                          size: 110,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 40),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: theme.colorScheme.secondary.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            //
            // DOT INDICATOR
            //
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                    (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 10,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? theme.colorScheme.primary
                        : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            //
            // CHECKBOX - Μόνο στην τελευταία σελίδα
            //
            if (_currentPage == pages.length - 1) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Checkbox(
                      value: _skipOnboarding,
                      onChanged: (value) {
                        setState(() {
                          _skipOnboarding = value ?? false;
                        });
                        // Αποθήκευση αμέσως όταν αλλάζει
                        _saveOnboardingPreference(_skipOnboarding);
                      },
                      activeColor: theme.colorScheme.primary,
                    ),
                    Expanded(
                      child: Text(
                        "Να μην εμφανίζεται ξανά",
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            //
            // BUTTON
            //
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage == pages.length - 1) {
                      // Αποθήκευση της τελικής προτίμησης
                      _saveOnboardingPreference(_skipOnboarding);
                      context.go('/login');
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _currentPage == pages.length - 1
                        ? "Ξεκινάμε"
                        : "Επόμενο",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _OnboardData {
  final String title;
  final String subtitle;
  final IconData icon;

  _OnboardData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}