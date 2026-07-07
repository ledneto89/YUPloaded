
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TaxesPage extends StatefulWidget {
const TaxesPage({super.key});

@override
State<TaxesPage> createState() => _TaxesPageState();
}

class _TaxesPageState extends State<TaxesPage> {
String _selectedYear = '2026';

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
child: SingleChildScrollView(
padding: const EdgeInsets.all(24),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('Taxes', style: GoogleFonts.barlowCondensed(fontSize: 32, fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: -0.5)),

const SizedBox(height: 12),

// YEAR SELECTOR
Row(
children: ['2024', '2025', '2026'].map((year) {
final isSelected = _selectedYear == year;
return GestureDetector(
onTap: () => setState(() => _selectedYear = year),
child: Container(
margin: const EdgeInsets.only(right: 8),
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
decoration: BoxDecoration(
color: isSelected ? orange.withValues(alpha: 0.12) : Colors.transparent,
borderRadius: BorderRadius.circular(8),
border: isSelected ? Border.all(color: orange) : null,
),
child: Text(year, style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w800, color: isSelected ? orange : textMuted)),
),
);
}).toList(),
),

const SizedBox(height: 20),

// SUMMARY CARD
Container(
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
child: Column(
children: [
_buildTaxRow('TOTAL INCOME', '\$89,400', success),
const SizedBox(height: 12),
_buildTaxRow('TOTAL EXPENSES', '\$24,600', orange),
const Divider(height: 24, color: Color(0xFF1C2E45)),
_buildTaxRow('NET PROFIT', '\$64,800', textPrimary, large: true),
],
),
),

const SizedBox(height: 16),

// BREAKDOWN
Text('EXPENSE BREAKDOWN', style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: textMuted)),
const SizedBox(height: 8),
Container(
decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
child: Column(
children: [
_buildBreakdownRow('⛽', 'Fuel', '\$14,200'),
_buildBreakdownRow('🔧', 'Repairs', '\$3,400'),
_buildBreakdownRow('🛣️', 'Tolls', '\$1,800'),
_buildBreakdownRow('📋', 'Permits', '\$900'),
_buildBreakdownRow('🏨', 'Lodging', '\$2,100'),
_buildBreakdownRow('👷', 'Lumper', '\$1,200'),
_buildBreakdownRow('📦', 'Other', '\$1,000', isLast: true),
],
),
),

const SizedBox(height: 16),

// MILEAGE
Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('MILEAGE SUMMARY', style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: textMuted)),
const SizedBox(height: 8),
Text('94,200 total miles', style: GoogleFonts.barlowCondensed(fontSize: 24, fontWeight: FontWeight.w900, color: textPrimary)),
const SizedBox(height: 4),
Text('IRS deduction: \$65,940', style: GoogleFonts.barlowCondensed(fontSize: 18, fontWeight: FontWeight.w800, color: success)),
const SizedBox(height: 4),
Text('Based on IRS standard mileage rate \$0.70/mi', style: GoogleFonts.barlow(fontSize: 11, color: textMuted)),
],
),
),

const SizedBox(height: 20),

// EXPORT BUTTONS
Row(
children: [
Expanded(
child: OutlinedButton(
onPressed: () {},
style: OutlinedButton.styleFrom(
side: const BorderSide(color: Color(0xFF1C2E45)),
padding: const EdgeInsets.symmetric(vertical: 16),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
),
child: Text('EXPORT CSV', style: GoogleFonts.barlowCondensed(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary)),
),
),
const SizedBox(width: 12),
Expanded(
child: ElevatedButton(
onPressed: () {},
style: ElevatedButton.styleFrom(
backgroundColor: orange,
padding: const EdgeInsets.symmetric(vertical: 16),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
),
child: Text('TAX PDF', style: GoogleFonts.barlowCondensed(fontSize: 15, fontWeight: FontWeight.w800, color: background)),
),
),
],
),

const SizedBox(height: 24),
],
),
),
),
);
}

Widget _buildTaxRow(String label, String value, Color color, {bool large = false}) {
return Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(label, style: GoogleFonts.barlowCondensed(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1, color: textMuted)),
Text(value, style: GoogleFonts.barlowCondensed(fontSize: large ? 32 : 22, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5)),
],
);
}

Widget _buildBreakdownRow(String icon, String label, String amount, {bool isLast = false}) {
return Container(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: border))),
child: Row(
children: [
Text(icon, style: const TextStyle(fontSize: 18)),
const SizedBox(width: 12),
Expanded(child: Text(label, style: GoogleFonts.barlow(fontSize: 14, color: textPrimary, fontWeight: FontWeight.w500))),
Text(amount, style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
],
),
);
}
}

