import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/pricing_plan.dart';

class PricingScreen extends StatefulWidget {
  final String? selectedPlan;

  const PricingScreen({super.key, this.selectedPlan});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  String? _selectedPlanId;

  @override
  void initState() {
    super.initState();
    _selectedPlanId = widget.selectedPlan;
  }

  void _selectPlan(String planId) {
    setState(() => _selectedPlanId = planId);
  }

  void _continueWithPlan() {
    if (_selectedPlanId != null) {
      // Επιστροφή στο register με το επιλεγμένο plan
      context.pop(_selectedPlanId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Επιλογή Πακέτου"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 30),

            // Pricing Cards
            ...PricingPlan.allPlans.map((plan) => _buildPricingCard(plan)),

            const SizedBox(height: 30),

            // Continue Button
            _buildContinueButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          "Επιλέξτε το Πακέτο Σας",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Αναβαθμίστε την ψηφιακή σας ταυτότητα με τα πακέτα μας",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPricingCard(PricingPlan plan) {
    final isSelected = _selectedPlanId == plan.id;
    final isPopular = plan.id == 'pro';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
        color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.05) : Colors.white,
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          // Header with popular badge
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isPopular ? Theme.of(context).colorScheme.primary : null,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isPopular ? Colors.white : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.description,
                        style: TextStyle(
                          color: isPopular ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Δημοφιλές",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Price
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  plan.priceText,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (plan.id == 'free') ...[
                  const SizedBox(height: 8),
                  Text(
                    "Μετά από 10 scans: €10/έτος",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Features
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: plan.features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
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
            ),
          ),

          // Select Button
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _selectPlan(plan.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  foregroundColor: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  isSelected ? "Επιλεγμένο" : "Επιλογή",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _selectedPlanId != null ? _continueWithPlan : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          "ΣΥΝΕΧΕΙΑ ΜΕ ΕΠΙΛΟΓΗ ΠΑΚΕΤΟΥ",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}