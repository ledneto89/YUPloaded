import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_page.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});
  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  int _selectedPlan = 0;
  bool _isLoading = false;

  static const String stripePaymentLink = 'pk_test_51Tq66HEuBHG28BjubWmjSiDuhr6fwO6HzGAKHeKdOotrJQBL2N5JgCXHsltAZ0jlHY1ZFslP5mwAyEF0XnKhcooM00VwXftzim';


  static const Color background = Color(0xFF0B1628);
  static const Color surface = Color(0xFF122035);
  static const Color border = Color(0xFF1C2E45);
  static const Color orange = Color(0xFFF5921E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF5A7A9A);
  static const Color success = Color(0xFF4ADE80);
  static const Color gold = Color(0xFFFFD700);

  final List<Map<String, dynamic>> _plans = [
    {
      'title': 'FREE',
      'subtitle': '3 loads per month - no card needed',
      'price': '0',
      'isFree': true,
      'isFounder': false,
    },
    {
      'title': 'FOUNDING MEMBER',
      'subtitle': 'First 100 only - locked for life',
      'price': '19.99',
      'isFree': false,
      'isFounder': true,
    },
    {
      'title': 'STANDARD',
      'subtitle': 'Full product - cancel anytime',
      'price': '29.99',
      'isFree': false,
      'isFounder': false,
    },
  ];

  Future<void> _selectPlan() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final plan = _plans[_selectedPlan];
      final isFree = plan['isFree'] as bool;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'plan': plan['title'],
        'planPrice': plan['price'],
        'isFree': isFree,
        'freeLoadsUsed': 0,
        'trialStarted': FieldValue.serverTimestamp(),
        'trialActive': !isFree,
      });

      if (isFree) {
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()));
      } else {
        if (mounted) {
          await launchUrl(Uri.parse(stripePaymentLink), mode: LaunchMode.externalApplication);
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ' + e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.local_shipping, color: Color(0xFFF5921E), size: 40),
              const SizedBox(height: 16),
              Text('Choose Your Plan.', style: GoogleFonts.barlowCondensed(fontSize: 32, fontWeight: FontWeight.w900, color: textPrimary)),
              Text('Start free. Upgrade when ready.', style: GoogleFonts.barlowCondensed(fontSize: 22, fontWeight: FontWeight.w900, color: orange)),
              const SizedBox(height: 10),
              Text('Try 3 free loads and see why drivers choose YUPLOADED.', style: GoogleFonts.barlow(fontSize: 13, color: textMuted), textAlign: TextAlign.center),
              const SizedBox(height: 28),

              ..._plans.asMap().entries.map((entry) {
                final index = entry.key;
                final plan = entry.value;
                final isSelected = _selectedPlan == index;
                final isFree = plan['isFree'] as bool;
                final isFounder = plan['isFounder'] as bool;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPlan = index),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected && isFounder ? orange : isSelected ? surface : surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? (isFounder ? orange : orange) : border, width: isSelected ? 2 : 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                if (isFounder) Padding(padding: const EdgeInsets.only(right: 6), child: Icon(Icons.star, color: isSelected ? background : gold, size: 14)),
                                Text(plan['title'] as String, style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w900, color: isSelected && isFounder ? background : textPrimary)),
                                if (isFounder) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: isSelected ? background.withValues(alpha: 0.2) : orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                                    child: Text('LIMITED', style: GoogleFonts.barlowCondensed(fontSize: 9, fontWeight: FontWeight.w900, color: isSelected ? background : orange, letterSpacing: 1)),
                                  ),
                                ],
                              ]),
                              const SizedBox(height: 2),
                              Text(plan['subtitle'] as String, style: GoogleFonts.barlow(fontSize: 11, color: isSelected && isFounder ? background.withValues(alpha: 0.7) : textMuted)),
                            ]),
                          ),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text(isFree ? 'FREE' : 'USD ' + (plan['price'] as String), style: GoogleFonts.barlowCondensed(fontSize: isFree ? 20 : 22, fontWeight: FontWeight.w900, color: isFree ? success : isSelected && isFounder ? background : textPrimary, letterSpacing: -0.5)),
                            if (!isFree) Text('/mo', style: GoogleFonts.barlow(fontSize: 10, color: isSelected && isFounder ? background.withValues(alpha: 0.5) : textMuted)),
                          ]),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 20),

              if (_selectedPlan == 0)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: success.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: success.withValues(alpha: 0.2))),
                  child: Column(children: [
                    Text('What you get free:', style: GoogleFonts.barlowCondensed(fontSize: 14, fontWeight: FontWeight.w800, color: success)),
                    const SizedBox(height: 8),
                    _featureRow('3 loads per month'),
                    _featureRow('Full document upload flow'),
                    _featureRow('Expense tracking'),
                    _featureRow('Invoice generation'),
                    const SizedBox(height: 8),
                    Text('No credit card required', style: GoogleFonts.barlowCondensed(fontSize: 13, fontWeight: FontWeight.w800, color: success)),
                  ]),
                ),

              if (_selectedPlan == 1)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: orange.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: orange.withValues(alpha: 0.3))),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                      const SizedBox(width: 6),
                      Text('Founding Member Benefits', style: GoogleFonts.barlowCondensed(fontSize: 14, fontWeight: FontWeight.w800, color: orange)),
                    ]),
                    const SizedBox(height: 8),
                    _featureRow('Unlimited loads'),
                    _featureRow('Invoice auto-sent to broker'),
                    _featureRow('Full packet to dispatcher'),
                    _featureRow('Document repository'),
                    _featureRow('Tax summary export'),
                    _featureRow('Road to Verified tracker'),
                    _featureRow('Broker confirmation emails'),
                    _featureRow('Driver ratings from brokers'),
                    const SizedBox(height: 8),
                    Text('USD 19.99/mo locked for life', style: GoogleFonts.barlowCondensed(fontSize: 13, fontWeight: FontWeight.w800, color: orange)),
                  ]),
                ),

              if (_selectedPlan == 2)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                  child: Column(children: [
                    Text('Everything included:', style: GoogleFonts.barlowCondensed(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary)),
                    const SizedBox(height: 8),
                    _featureRow('Unlimited loads'),
                    _featureRow('Invoice auto-sent to broker'),
                    _featureRow('Full packet to dispatcher'),
                    _featureRow('Document repository'),
                    _featureRow('Tax summary export'),
                    _featureRow('Road to Verified tracker'),
                    _featureRow('Broker confirmation emails'),
                    _featureRow('Driver ratings from brokers'),
                    const SizedBox(height: 8),
                    Text('30-day free trial', style: GoogleFonts.barlowCondensed(fontSize: 13, fontWeight: FontWeight.w800, color: success)),
                  ]),
                ),

              const SizedBox(height: 24),

              // VERIFIED SECTION
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2A4060)),
                ),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.shield, color: Color(0xFFF5921E), size: 20),
                      const SizedBox(width: 8),
                      Text('YUPLOADED VERIFIED', style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w900, color: orange, letterSpacing: 1)),
                    ]),
                    const SizedBox(height: 6),
                    Text('Earned. Not bought.', style: GoogleFonts.barlowCondensed(fontSize: 18, fontWeight: FontWeight.w900, color: textPrimary)),
                    const SizedBox(height: 8),
                    Text('Complete 100 broker-confirmed loads and earn the only verification in trucking that cannot be faked or purchased. Your history speaks for itself.', style: GoogleFonts.barlow(fontSize: 13, color: textMuted), textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    Text('500 loads. 4.8 stars. That\'s a career.', style: GoogleFonts.barlowCondensed(fontSize: 14, fontWeight: FontWeight.w800, color: orange), textAlign: TextAlign.center),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _selectPlan,
                  style: ElevatedButton.styleFrom(backgroundColor: orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _selectedPlan == 0 ? 'START FOR FREE' : 'START FREE TRIAL',
                          style: GoogleFonts.barlowCondensed(fontSize: 18, fontWeight: FontWeight.w900, color: background, letterSpacing: 2),
                        ),
                ),
              ),

              const SizedBox(height: 12),
              Text(
                _selectedPlan == 0
                    ? 'No credit card required - upgrade anytime'
                    : 'No charge for 30 days - cancel before Day 31 and pay nothing',
                style: GoogleFonts.barlow(fontSize: 11, color: textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        const Icon(Icons.check, color: Color(0xFF4ADE80), size: 14),
        const SizedBox(width: 8),
        Text(text, style: GoogleFonts.barlow(fontSize: 13, color: textPrimary)),
      ]),
    );
  }
}
