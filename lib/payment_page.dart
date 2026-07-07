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

// REPLACE WITH YOUR ACTUAL STRIPE PAYMENT LINK
static const String stripePaymentLink = 'pk_test_51Tq66HEuBHG28BjubWmjSiDuhr6fwO6HzGAKHeKdOotrJQBL2N5JgCXHsltAZ0jlHY1ZFslP5mwAyEF0XnKhcooM00VwXftzim';

static const Color background = Color(0xFF0B1628);
static const Color surface = Color(0xFF122035);
static const Color border = Color(0xFF1C2E45);
static const Color orange = Color(0xFFF5921E);
static const Color textPrimary = Color(0xFFFFFFFF);
static const Color textMuted = Color(0xFF5A7A9A);
static const Color success = Color(0xFF4ADE80);

final List<Map<String, dynamic>> _plans = [
{'title': 'FREE', 'subtitle': '3 loads per month - no card needed', 'price': '0', 'isPrimary': false, 'isFree': true},
{'title': 'FOUNDING MEMBER', 'subtitle': 'Locked for life - First 100 only', 'price': '14', 'isPrimary': true, 'isFree': false},
{'title': 'PRO', 'subtitle': 'Unlimited loads - invoice email - tax export', 'price': '19', 'isPrimary': false, 'isFree': false},
{'title': 'FLEET', 'subtitle': 'Up to 10 trucks', 'price': '39', 'isPrimary': false, 'isFree': false},
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
if (mounted) {
Navigator.pushReplacement(
context,
MaterialPageRoute(builder: (_) => const HomePage()),
);
}
} else {
if (mounted) {
await launchUrl(Uri.parse(stripePaymentLink), mode: LaunchMode.externalApplication);
Navigator.pushReplacement(
context,
MaterialPageRoute(builder: (_) => const HomePage()),
);
}
}
} catch (e) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Error: ' + e.toString()), backgroundColor: Colors.red),
);
}
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
const Icon(Icons.lock, color: Color(0xFFF5921E), size: 40),
const SizedBox(height: 16),
Text('Choose Your Plan.', style: GoogleFonts.barlowCondensed(fontSize: 32, fontWeight: FontWeight.w900, color: textPrimary)),
Text('Start free. Upgrade anytime.', style: GoogleFonts.barlowCondensed(fontSize: 24, fontWeight: FontWeight.w900, color: orange)),
const SizedBox(height: 10),
Text('Try 3 free loads and see why drivers love YUPLOADED.', style: GoogleFonts.barlow(fontSize: 13, color: textMuted), textAlign: TextAlign.center),
const SizedBox(height: 28),

..._plans.asMap().entries.map((entry) {
final index = entry.key;
final plan = entry.value;
final isSelected = _selectedPlan == index;
final isPrimary = plan['isPrimary'] as bool;
final isFree = plan['isFree'] as bool;

return Padding(
padding: const EdgeInsets.only(bottom: 8),
child: GestureDetector(
onTap: () => setState(() => _selectedPlan = index),
child: Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: isSelected && isPrimary ? orange : isSelected && isFree ? surface : surface,
borderRadius: BorderRadius.circular(12),
border: Border.all(
color: isSelected ? orange : border,
width: isSelected ? 2 : 1,
),
),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Expanded(
child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
Row(children: [
Text(plan['title'] as String, style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w900, color: isSelected && isPrimary ? background : textPrimary)),
if (isPrimary) ...[
const SizedBox(width: 8),
Container(
padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
decoration: BoxDecoration(color: isSelected ? background.withValues(alpha: 0.2) : orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
child: Text('LIMITED', style: GoogleFonts.barlowCondensed(fontSize: 9, fontWeight: FontWeight.w900, color: isSelected ? background : orange, letterSpacing: 1)),
),
],
]),
Text(plan['subtitle'] as String, style: GoogleFonts.barlow(fontSize: 11, color: isSelected && isPrimary ? background.withValues(alpha: 0.6) : textMuted)),
]),
),
Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
if (!isFree) Text('USD', style: GoogleFonts.barlow(fontSize: 10, color: isSelected && isPrimary ? background : textMuted)),
const SizedBox(width: 2),
Text(isFree ? 'FREE' : plan['price'] as String, style: GoogleFonts.barlowCondensed(fontSize: isFree ? 20 : 28, fontWeight: FontWeight.w900, color: isFree ? success : isSelected && isPrimary ? background : textPrimary, letterSpacing: -1)),
]),
if (!isFree) Text('/mo', style: GoogleFonts.barlow(fontSize: 10, color: isSelected && isPrimary ? background.withValues(alpha: 0.5) : textMuted)),
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
Text('3 loads per month', style: GoogleFonts.barlow(fontSize: 13, color: textPrimary)),
Text('Full YUP/NOPE upload flow', style: GoogleFonts.barlow(fontSize: 13, color: textPrimary)),
Text('Expense tracking', style: GoogleFonts.barlow(fontSize: 13, color: textPrimary)),
const SizedBox(height: 8),
Text('No credit card required', style: GoogleFonts.barlowCondensed(fontSize: 13, fontWeight: FontWeight.w800, color: success)),
]),
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
: 'No charge for 30 days - Cancel before Day 31 and pay nothing',
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
}
