import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/card_model.dart';
/// Pages
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/cards_management_screen.dart';
import 'screens/card_edit_screen.dart';
import 'screens/pricing_screen.dart';
import 'screens/google_payment_screen.dart';
import 'models/pricing_plan.dart';
import 'screens/analytics_screen.dart';
import 'screens/nfc_writing_screen.dart';
import 'screens/card_view_screen.dart';
import 'screens/debug_qr_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/public_card_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  runApp(const NexusLinkApp());
}

class NexusLinkApp extends StatefulWidget {
  const NexusLinkApp({super.key});

  @override
  State<NexusLinkApp> createState() => _NexusLinkAppState();
}

class _NexusLinkAppState extends State<NexusLinkApp> {
  late final GoRouter _router;
  bool _isRouterInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeRouter();
  }

  Future<void> _initializeRouter() async {
    // Check onboarding preference
    final prefs = await SharedPreferences.getInstance();
    final skipOnboarding = prefs.getBool('skip_onboarding') ?? false;

    _router = GoRouter(
      initialLocation: skipOnboarding ? '/login' : '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/cards',
          builder: (context, state) => const CardsManagementScreen(),
        ),
        GoRoute(
          path: '/cards/edit',
          builder: (context, state) => const CardEditScreen(),
        ),
        GoRoute(
          path: '/nfc-write',
          name: 'nfc-write',
          builder: (context, state) {
            final card = state.extra as BusinessCard;
            return NfcWritingScreen(card: card);
          },
        ),
        GoRoute(
          path: '/qr-scanner',
          builder: (context, state) => const QrScannerScreen(),
        ),
        GoRoute(
          path: '/card-view',
          builder: (context, state) {
            final card = state.extra as BusinessCard;
            return CardViewScreen(card: card);
          },
        ),
        GoRoute(
          path: '/debug-qr',
          builder: (context, state) {
            final qrData = state.extra as String;
            return DebugQrScreen(qrData: qrData);
          },
        ),
        GoRoute(
          path: '/pricing',
          builder: (context, state) => const PricingScreen(),
        ),
        GoRoute(
          path: '/cards/edit/:cardId',
          builder: (context, state) {
            final card = state.extra as BusinessCard?;
            return CardEditScreen(card: card, isEditing: true);
          },
        ),
        GoRoute(
          path: '/google-payment',
          builder: (context, state) {
            final plan = state.extra as PricingPlan;
            return GooglePaymentScreen(plan: plan);
          },
        ),
        GoRoute(
          path: '/analytics',
          builder: (context, state) => const AnalyticsScreen(),
        ),
        GoRoute(
          path: '/pro_home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/c/:cardId',
          builder: (context, state) {
            final cardId = state.pathParameters['cardId']!;
            return PublicCardScreen(cardId: cardId);
          },
        ),
      ],
    );

    setState(() {
      _isRouterInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRouterInitialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: "NexusLink Card NFC",
      routerConfig: _router,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: ThemeMode.system,
    );
  }
}

//
// ─────────────────────────────────────────────
//     THEME (Modern + Business)
// ─────────────────────────────────────────────
//

final ThemeData _lightTheme = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  primaryColor: const Color(0xFF2E5AAC),
  scaffoldBackgroundColor: const Color(0xFFF5F7FA),
  textTheme: GoogleFonts.interTextTheme(),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF2E5AAC),
    primary: const Color(0xFF2E5AAC),
    secondary: const Color(0xFF1A1A1A),
    brightness: Brightness.light,
  ),
);

final ThemeData _darkTheme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  primaryColor: const Color(0xFF7BA7FF),
  scaffoldBackgroundColor: const Color(0xFF0D0F14),
  textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF7BA7FF),
    primary: const Color(0xFF7BA7FF),
    secondary: Colors.white,
    brightness: Brightness.dark,
  ),
);