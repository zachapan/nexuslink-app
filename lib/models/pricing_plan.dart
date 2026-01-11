class PricingPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String period; // 'month', 'year', 'lifetime'
  final List<String> features;
  final int maxScans;
  final bool hasAnalytics;
  final bool hasCustomization;
  final bool hasTeamManagement;

  const PricingPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.period,
    required this.features,
    required this.maxScans,
    required this.hasAnalytics,
    required this.hasCustomization,
    required this.hasTeamManagement,
  });

  // Free Plan
  static PricingPlan get free => PricingPlan(
    id: 'free',
    name: 'Basic / Free',
    description: 'Ιδανικό για αρχάριους',
    price: 0,
    period: 'year',
    maxScans: 10,
    features: [
      '1 Ψηφιακή Κάρτα',
      'NFC Sharing',
      'QR Code',
      'Βασικό Προφίλ',
      '10 δωρεάν scans',
      'Φιλική υποστήριξη',
    ],
    hasAnalytics: false,
    hasCustomization: false,
    hasTeamManagement: false,
  );

  // Pro Plan
  static PricingPlan get pro => PricingPlan(
    id: 'pro',
    name: 'Pro / Business',
    description: 'Για επαγγελματίες',
    price: 55,
    period: 'year',
    maxScans: -1, // Unlimited
    features: [
      '5 Ψηφιακές Κάρτες',
      'Απεριόριστα Scans',
      'Στατιστικά & Analytics',
      'Προσαρμοσμένο Branding',
      'Email Marketing',
      'CRM Integration',
      'Προτεραιότητα υποστήριξης',
    ],
    hasAnalytics: true,
    hasCustomization: true,
    hasTeamManagement: false,
  );

  // Enterprise Plan
  static PricingPlan get enterprise => PricingPlan(
    id: 'enterprise',
    name: 'Enterprise',
    description: 'Για ομάδες & οργανισμούς',
    price: 99,
    period: 'year',
    maxScans: -1, // Unlimited
    features: [
      'Απεριόριστες Κάρτες',
      'Απεριόριστα Scans',
      'Advanced Analytics',
      'Team Management',
      'White-label Solution',
      'API Access',
      'Dedicated Support',
      'Custom Development',
    ],
    hasAnalytics: true,
    hasCustomization: true,
    hasTeamManagement: true,
  );

  static List<PricingPlan> get allPlans => [free, pro, enterprise];

  String get priceText {
    if (price == 0) return 'Δωρεάν';
    return '€$price/${period == 'year' ? 'έτος' : 'μήνας'}';
  }

  bool get isFree => price == 0;
}