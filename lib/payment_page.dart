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
  int _foundingMembersLeft = 100;
  bool _foundingFull = false;
  bool _isFleetOwner = false;

  static const String stripeFoundingLink = 'https://buy.stripe.com/test_cNi00j7JifeJbFp5GB2VG01';
  static const String stripeStandardLink = 'https://buy.stripe.com/test_eVqcN5fbKaYt8td6KF2VG02';
  static const String stripeFleetLink = 'https://buy.stripe.com/test_bJecN51kU8Ql4cXd932VG03';

  static const Color background = Color(0xFF0B1628);
  static const Color surface = Color(0xFF122035);
  static const Color border = Color(0xFF1C2E45);
  static const Color orange = Color(0xFFF5921E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF5A7A9A);
  static const Color success = Color(0xFF4ADE80);
  static const Color danger = Color(0xFFEF4444);
  static const Color gold = Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        setState(() => _isFleetOwner = userDoc.data()?['isFleetOwner'] ?? false);
        if (_isFleetOwner) setState(() => _selectedPlan = 3);
      }
      final doc = await FirebaseFirestore.instance.collection('config').doc('founding_members').get();
      if (doc.exists) {
        final count = (doc.data()?['count'] ?? 0) as int;
        final remaining = 100 - count;
        setState(() { _foundingMembersLeft = remaining.clamp(0, 100); _foundingFull = remaining <= 0; });
      }
    } catch (e) {}
  }

  Future<void> _selectPlan() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String planName;
      String planPrice;
      bool isFree;
      String stripeLink;

      switch (_selectedPlan) {
        case 0: planName = 'FREE'; planPrice = '0'; isFree = true; stripeLink = ''; break;
        case 1: planName = 'FOUNDING MEMBER'; planPrice = '19.99'; isFree = false; stripeLink = stripeFoundingLink; break;
        case 2: planName = 'STANDARD'; planPrice = '29.99'; isFree = false; stripeLink = stripeStandardLink; break;
        case 3: planName = 'FLEET'; planPrice = '79.99'; isFree = false; stripeLink = stripeFleetLink; break;
        default: planName = 'FREE'; planPrice = '0'; isFree = true; stripeLink = '';
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'plan': planName, 'planPrice': planPrice, 'isFree': isFree,
        'trialStarted': FieldValue.serverTimestamp(), 'trialActive': !isFree,
      });

      if (_selectedPlan == 1) {
        await FirebaseFirestore.instance.collection('config').doc('founding_members').set({'count': FieldValue.increment(1)}, SetOptions(merge: true));
      }

      if (isFree) {
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()));
      } else {
        if (mounted) {
          await launchUrl(Uri.parse(stripeLink), mode: LaunchMode.externalApplication);
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            const SizedBox(height: 24),
            const Icon(Icons.local_shipping, color: Color(0xFFF5921E), size: 40),
            const SizedBox(height: 16),
            Text('Choose Your Plan.', style: GoogleFonts.barlowCondensed(fontSize: 32, fontWeight: FontWeight.w900, color: textPrimary)),
            Text('Start free. Upgrade when ready.', style: GoogleFonts.barlowCondensed(fontSize: 22, fontWeight: FontWeight.w900, color: orange)),
            const SizedBox(height: 10),
            Text('Try 3 free loads and see why drivers choose YUPLOADED.', style: GoogleFonts.barlow(fontSize: 13, color: textMuted), textAlign: TextAlign.center),
            const SizedBox(height: 28),

            // FREE
            _buildPlanCard(index: 0, title: 'FREE', subtitle: '3 loads per month - no card needed', price: 'FREE', priceColor: success),
            const SizedBox(height: 10),

            // FOUNDING MEMBER
            if (!_isFleetOwner) ...[
              _buildPlanCard(
                index: 1, title: 'FOUNDING MEMBER',
                subtitle: 'First 100 only - locked for life',
                price: 'USD 19.99/mo',
                badge: 'FIRST 100 ONLY',
                counter: _foundingFull ? 'SPOTS FULL' : _foundingMembersLeft.toString() + ' OF 100 SPOTS LEFT',
                counterColor: _foundingMembersLeft <= 20 ? danger : orange,
                disabled: _foundingFull,
              ),
              const SizedBox(height: 10),

              // STANDARD
              _buildPlanCard(index: 2, title: 'STANDARD', subtitle: 'Full product - cancel anytime', price: 'USD 29.99/mo'),
              const SizedBox(height: 10),
            ],

            // FLEET
            _buildPlanCard(
              index: 3,
              title: 'FLEET',
              subtitle: 'Up to 10 trucks under one MC',
              price: 'USD 79.99/mo',
              badge: 'UNDER 10 TRUCKS',
              badgeColor: const Color(0xFF60A5FA),
            ),

            const SizedBox(height: 20),

            // FEATURES
            if (_selectedPlan == 0) _buildFeatureBox(success, 'What you get free:', ['3 loads per month', 'Full document upload', 'Expense tracking', 'Invoice generation', 'No credit card required']),
            if (_selectedPlan == 1 && !_foundingFull) _buildFeatureBox(orange, 'Founding Member Benefits:', ['Unlimited loads', 'Invoice auto-sent to broker', 'Full packet to dispatcher', 'Document repository', 'Tax summary', 'Road to Verified tracker', 'Broker confirmation emails', 'USD 19.99 locked for life']),
            if (_selectedPlan == 2) _buildFeatureBox(textPrimary, 'Everything included:', ['Unlimited loads', 'Invoice auto-sent to broker', 'Full packet to dispatcher', 'Document repository', 'Tax summary', 'Road to Verified tracker', 'Broker confirmation emails', '30-day free trial']),
            if (_selectedPlan == 3) _buildFeatureBox(const Color(0xFF60A5FA), 'Fleet Plan includes:', ['Up to 10 drivers under your MC', 'Each driver has own login', 'Fleet dashboard - see all loads', 'Individual driver verified tracking', 'All solo plan features', 'Unique fleet code for driver onboarding', '30-day free trial']),

            const SizedBox(height: 24),

            // VERIFIED SECTION
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF2A4060))),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.shield, color: Color(0xFFF5921E), size: 20),
                  const SizedBox(width: 8),
                  Text('YUPLOADED VERIFIED', style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w900, color: orange, letterSpacing: 1)),
                ]),
                const SizedBox(height: 6),
                Text('Earned. Not bought.', style: GoogleFonts.barlowCondensed(fontSize: 18, fontWeight: FontWeight.w900, color: textPrimary)),
                const SizedBox(height: 8),
                Text('Complete 100 broker-confirmed loads and earn the only verification in trucking that cannot be faked or purchased.', style: GoogleFonts.barlow(fontSize: 13, color: textMuted), textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Text('500 broker-confirmed loads. That\'s a career.', style: GoogleFonts.barlowCondensed(fontSize: 14, fontWeight: FontWeight.w800, color: orange), textAlign: TextAlign.center),
              ]),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: (_isLoading || (_selectedPlan == 1 && _foundingFull)) ? null : _selectPlan,
                style: ElevatedButton.styleFrom(backgroundColor: orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_selectedPlan == 0 ? 'START FOR FREE' : 'START FREE TRIAL', style: GoogleFonts.barlowCondensed(fontSize: 18, fontWeight: FontWeight.w900, color: background, letterSpacing: 2)),
              ),
            ),
            const SizedBox(height: 12),
            Text(_selectedPlan == 0 ? 'No credit card required - upgrade anytime' : 'No charge for 30 days - cancel before Day 31 and pay nothing', style: GoogleFonts.barlow(fontSize: 11, color: textMuted), textAlign: TextAlign.center),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  Widget _buildPlanCard({required int index, required String title, required String subtitle, required String price, String? badge, Color? badgeColor, String? counter, Color? counterColor, bool disabled = false, Color? priceColor}) {
    final isSelected = _selectedPlan == index;
    final isFounder = index == 1;
    return GestureDetector(
      onTap: disabled ? null : () => setState(() => _selectedPlan = index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isSelected && isFounder ? orange : surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? orange : border, width: isSelected ? 2 : 1)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (badge != null) Text(badge, style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w900, color: isSelected && isFounder ? background : (badgeColor ?? gold), letterSpacing: 1)),
            if (counter != null) Text(counter, style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w800, color: isSelected && isFounder ? background : (counterColor ?? orange))),
            Text(title, style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w900, color: isSelected && isFounder ? background : textPrimary)),
            Text(subtitle, style: GoogleFonts.barlow(fontSize: 11, color: isSelected && isFounder ? background.withValues(alpha: 0.7) : textMuted)),
          ])),
          Text(price, style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w900, color: priceColor ?? (isSelected && isFounder ? background : textPrimary))),
        ]),
      ),
    );
  }

  Widget _buildFeatureBox(Color color, String title, List<String> features) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(children: [
        Text(title, style: GoogleFonts.barlowCondensed(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 8),
        ...features.map((f) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [Icon(Icons.check, color: success, size: 14), const SizedBox(width: 8), Text(f, style: GoogleFonts.barlow(fontSize: 13, color: textPrimary))]))),
      ]),
    );
  }
}
