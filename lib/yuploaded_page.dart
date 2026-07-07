import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';

class YUPLOADEDPage extends StatelessWidget {
final String loadNumber;
const YUPLOADEDPage({super.key, required this.loadNumber});

static const Color background = Color(0xFF0B1628);
static const Color surface = Color(0xFF122035);
static const Color border = Color(0xFF1C2E45);
static const Color orange = Color(0xFFF5921E);
static const Color textPrimary = Color(0xFFFFFFFF);
static const Color textMuted = Color(0xFF5A7A9A);
static const Color success = Color(0xFF4ADE80);

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: background,
body: SafeArea(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
crossAxisAlignment: CrossAxisAlignment.center,
children: [
Container(
width: 80, height: 80,
decoration: BoxDecoration(color: success.withValues(alpha: 0.08), shape: BoxShape.circle, border: Border.all(color: success.withValues(alpha: 0.3), width: 2)),
child: const Center(child: Text('✓', style: TextStyle(color: Color(0xFF4ADE80), fontSize: 40))),
),
const SizedBox(height: 24),
Text('✓ YUPLOADED.', style: GoogleFonts.barlowCondensed(fontSize: 52, fontWeight: FontWeight.w900, color: orange, letterSpacing: -1, height: 1)),
const SizedBox(height: 16),
Text('Your invoice is on its way.', style: GoogleFonts.barlow(fontSize: 18, color: textPrimary), textAlign: TextAlign.center),
const SizedBox(height: 4),
Text('Go get some miles.', style: GoogleFonts.barlow(fontSize: 18, color: textMuted), textAlign: TextAlign.center),
const SizedBox(height: 32),
Text('✓ Invoice sent to broker', style: GoogleFonts.barlow(fontSize: 14, color: success)),
const SizedBox(height: 6),
Text('✓ Full packet sent to dispatcher', style: GoogleFonts.barlow(fontSize: 14, color: success)),
const SizedBox(height: 6),
Text('✓ Load saved as $loadNumber', style: GoogleFonts.barlow(fontSize: 14, color: success)),
const SizedBox(height: 48),
SizedBox(
width: double.infinity,
height: 52,
child: OutlinedButton(
onPressed: () {
Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomePage()), (route) => false);
},
style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF1C2E45), width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
child: Text('BACK TO HOME', style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: 1)),
),

),
],
),
),
),
);
}
}