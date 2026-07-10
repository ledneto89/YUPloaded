import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaxesPage extends StatefulWidget {
const TaxesPage({super.key});
@override
State<TaxesPage> createState() => _TaxesPageState();
}

class _TaxesPageState extends State<TaxesPage> {
int _selectedYear = DateTime.now().year;

static const Color background = Color(0xFF0B1628);
static const Color surface = Color(0xFF122035);
static const Color border = Color(0xFF1C2E45);
static const Color orange = Color(0xFFF5921E);
static const Color textPrimary = Color(0xFFFFFFFF);
static const Color textMuted = Color(0xFF5A7A9A);
static const Color success = Color(0xFF4ADE80);

final Map<String, IconData> _categoryIcons = {
'Fuel': Icons.local_gas_station,
'Repairs': Icons.build,
'Tolls': Icons.toll,
'Permits': Icons.description,
'Lodging': Icons.hotel,
'Lumper': Icons.person,
'Other': Icons.more_horiz,
};

@override
Widget build(BuildContext context) {
final user = FirebaseAuth.instance.currentUser;

return Scaffold(
backgroundColor: background,
body: SafeArea(
child: SingleChildScrollView(
padding: const EdgeInsets.all(24),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
GestureDetector(
onTap: () => Navigator.pop(context),
child: Container(width: 36, height: 36, decoration: BoxDecoration(color: orange, shape: BoxShape.circle), child: const Center(child: Icon(Icons.chevron_left, color: Colors.white, size: 22))),
),
const SizedBox(width: 12),
Text('Taxes', style: GoogleFonts.barlowCondensed(fontSize: 32, fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: -0.5)),
],
),
const SizedBox(height: 16),

Row(
children: [2024, 2025, 2026].map((year) {
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
child: Text(year.toString(), style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w800, color: isSelected ? orange : textMuted)),
),
);
}).toList(),
),

const SizedBox(height: 20),

if (user != null)
StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance.collection('loads').where('userId', isEqualTo: user.uid).snapshots(),
builder: (context, loadsSnapshot) {
return StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance.collection('expenses').where('userId', isEqualTo: user.uid).snapshots(),
builder: (context, expensesSnapshot) {
final allLoads = loadsSnapshot.data?.docs ?? [];
final allExpenses = expensesSnapshot.data?.docs ?? [];

final yearLoads = allLoads.where((doc) {
final data = doc.data() as Map<String, dynamic>;
final createdAt = data['createdAt'];
if (createdAt == null) return false;
try {
final date = (createdAt as dynamic).toDate() as DateTime;
return date.year == _selectedYear;
} catch (e) { return false; }
}).toList();

final yearExpenses = allExpenses.where((doc) {
final data = doc.data() as Map<String, dynamic>;
final createdAt = data['createdAt'];
if (createdAt == null) return false;
try {
final date = (createdAt as dynamic).toDate() as DateTime;
return date.year == _selectedYear;
} catch (e) { return false; }
}).toList();

final totalIncome = yearLoads.fold<double>(0, (sum, doc) {
final data = doc.data() as Map<String, dynamic>;
return sum + ((data['rate'] ?? 0.0) as num).toDouble();
});

final totalExpenses = yearExpenses.fold<double>(0, (sum, doc) {
final data = doc.data() as Map<String, dynamic>;
return sum + ((data['amount'] ?? 0.0) as num).toDouble();
});

final totalMiles = yearLoads.fold<int>(0, (sum, doc) {
final data = doc.data() as Map<String, dynamic>;
return sum + ((data['mileage'] ?? 0) as num).toInt();
});

final netProfit = totalIncome - totalExpenses;
final mileageDeduction = totalMiles * 0.70;

final Map<String, double> categoryTotals = {};
for (final doc in yearExpenses) {
final data = doc.data() as Map<String, dynamic>;
final cat = data['category'] ?? 'Other';
final amount = ((data['amount'] ?? 0.0) as num).toDouble();
categoryTotals[cat] = (categoryTotals[cat] ?? 0) + amount;
}

return Column(
children: [
Container(
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
child: Column(
children: [
_buildTaxRow('TOTAL INCOME', 'USD ' + totalIncome.toStringAsFixed(0), success),
const SizedBox(height: 12),
_buildTaxRow('TOTAL EXPENSES', 'USD ' + totalExpenses.toStringAsFixed(0), orange),
const Divider(height: 24, color: Color(0xFF1C2E45)),
_buildTaxRow('NET PROFIT', 'USD ' + netProfit.toStringAsFixed(0), textPrimary, large: true),
],
),
),

const SizedBox(height: 16),

if (categoryTotals.isNotEmpty) ...[
Align(alignment: Alignment.centerLeft, child: Text('EXPENSE BREAKDOWN', style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: textMuted))),
const SizedBox(height: 8),
Container(
decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
child: Column(
children: categoryTotals.entries.map((entry) {
final isLast = entry.key == categoryTotals.keys.last;
return Container(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: border))),
child: Row(
children: [
Icon(_categoryIcons[entry.key] ?? Icons.more_horiz, color: orange, size: 18),
const SizedBox(width: 12),
Expanded(child: Text(entry.key, style: GoogleFonts.barlow(fontSize: 14, color: textPrimary, fontWeight: FontWeight.w500))),
Text('USD ' + entry.value.toStringAsFixed(0), style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
],
),
);
}).toList(),
),
),
const SizedBox(height: 16),
],

Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('MILEAGE SUMMARY', style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: textMuted)),
const SizedBox(height: 8),
Text(totalMiles.toString() + ' estimated miles', style: GoogleFonts.barlowCondensed(fontSize: 24, fontWeight: FontWeight.w900, color: textPrimary)),
const SizedBox(height: 4),
Text('IRS deduction: USD ' + mileageDeduction.toStringAsFixed(0), style: GoogleFonts.barlowCondensed(fontSize: 18, fontWeight: FontWeight.w800, color: success)),
const SizedBox(height: 4),
Text('Based on IRS standard mileage rate USD 0.70/mi', style: GoogleFonts.barlow(fontSize: 11, color: textMuted)),
const SizedBox(height: 4),
Text('Estimated from ZIP codes logged — not actual odometer miles', style: GoogleFonts.barlow(fontSize: 10, color: textMuted)),
],
),
),

const SizedBox(height: 20),

if (yearLoads.isEmpty && yearExpenses.isEmpty)
Padding(
padding: const EdgeInsets.all(24),
child: Center(child: Text('No data for ' + _selectedYear.toString() + ' yet.', style: GoogleFonts.barlow(fontSize: 14, color: textMuted))),
),

Row(
children: [
Expanded(
child: OutlinedButton(
onPressed: () {},
style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF1C2E45)), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
child: Text('EXPORT CSV', style: GoogleFonts.barlowCondensed(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary)),
),
),
const SizedBox(width: 12),
Expanded(
child: ElevatedButton(
onPressed: () {},
style: ElevatedButton.styleFrom(backgroundColor: orange, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
child: Text('TAX PDF', style: GoogleFonts.barlowCondensed(fontSize: 15, fontWeight: FontWeight.w800, color: background)),
),
),
],
),
const SizedBox(height: 24),
],
);
},
);
},
),
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
Text(value, style: GoogleFonts.barlowCondensed(fontSize: large ? 28 : 20, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5)),
],
);
}
}
