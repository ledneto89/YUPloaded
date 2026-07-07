import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_expense_page.dart';
import 'home_page.dart';
import 'profile_page.dart';

class ExpensesPage extends StatefulWidget {
const ExpensesPage({super.key});
@override
State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
String _selectedCategory = 'All';

static const Color background = Color(0xFF0B1628);
static const Color surface = Color(0xFF122035);
static const Color border = Color(0xFF1C2E45);
static const Color orange = Color(0xFFF5921E);
static const Color textPrimary = Color(0xFFFFFFFF);
static const Color textMuted = Color(0xFF5A7A9A);
static const Color success = Color(0xFF4ADE80);

final List<String> _categories = ['All', 'Fuel', 'Repairs', 'Tolls', 'Permits', 'Lodging', 'Lumper', 'Other'];

final Map<String, String> _categoryIcons = {
'Fuel': 'F',
'Repairs': 'R',
'Tolls': 'T',
'Permits': 'P',
'Lodging': 'L',
'Lumper': 'LU',
'Other': 'O',
};

Widget _buildBottomNav(BuildContext context) {
return Container(
decoration: BoxDecoration(color: const Color(0xFF0D1E30), border: Border(top: BorderSide(color: border))),
child: Row(
children: [
_buildNavItem(Icons.home, 'HOME', false, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()))),
_buildNavItem(Icons.local_shipping, 'LOADS', false, () => Navigator.pop(context)),
_buildNavItem(Icons.person, 'PROFILE', false, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()))),
],
),
);
}

Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
return Expanded(
child: GestureDetector(
onTap: onTap,
child: Padding(
padding: const EdgeInsets.symmetric(vertical: 12),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(icon, color: isActive ? orange : textMuted, size: 22),
const SizedBox(height: 4),
Text(label, style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: isActive ? orange : textMuted)),
if (isActive) Container(margin: const EdgeInsets.only(top: 4), width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFFF5921E), shape: BoxShape.circle)),
],
),
),
),
);
}

@override
Widget build(BuildContext context) {
final user = FirebaseAuth.instance.currentUser;
final now = DateTime.now();
final monthNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
final monthLabel = monthNames[now.month - 1] + ' ' + now.year.toString();

return Scaffold(
backgroundColor: background,
body: SafeArea(
child: Column(
children: [
Expanded(
child: SingleChildScrollView(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Padding(
padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
Text(monthLabel, style: GoogleFonts.barlow(fontSize: 13, color: textMuted)),
Text('Expenses', style: GoogleFonts.barlowCondensed(fontSize: 32, fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: -0.5)),
]),
GestureDetector(
onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpensePage())),
child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(12)), child: Text('+ ADD', style: GoogleFonts.barlowCondensed(fontSize: 15, fontWeight: FontWeight.w900, color: background))),
),
],
),
),
if (user != null)
StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
.collection('expenses')
.where('userId', isEqualTo: user.uid)
.orderBy('createdAt', descending: true)
.snapshots(),
builder: (context, snapshot) {
final docs = snapshot.data?.docs ?? [];
final thisMonthDocs = docs.where((doc) {
final data = doc.data() as Map<String, dynamic>;
final createdAt = data['createdAt'];
if (createdAt == null) return false;
final date = (createdAt as dynamic).toDate() as DateTime;
return date.month == now.month && date.year == now.year;
}).toList();

final totalAmount = thisMonthDocs.fold<double>(0, (sum, doc) {
final data = doc.data() as Map<String, dynamic>;
return sum + ((data['amount'] ?? 0.0) as num).toDouble();
});

final filteredDocs = _selectedCategory == 'All'
? thisMonthDocs
: thisMonthDocs.where((doc) {
final data = doc.data() as Map<String, dynamic>;
return data['category'] == _selectedCategory;
}).toList();

return Column(
children: [
Padding(
padding: const EdgeInsets.symmetric(horizontal: 24),
child: Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
Text('TOTAL EXPENSES', style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2, color: textMuted)),
const SizedBox(height: 4),
Text('USD ' + totalAmount.toStringAsFixed(0), style: GoogleFonts.barlowCondensed(fontSize: 36, fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: -1)),
Text(monthLabel + ' - ' + thisMonthDocs.length.toString() + ' entries', style: GoogleFonts.barlow(fontSize: 11, color: textMuted)),
]),
],
),
),
),
const SizedBox(height: 14),
SizedBox(
height: 36,
child: ListView(
scrollDirection: Axis.horizontal,
padding: const EdgeInsets.symmetric(horizontal: 24),
children: _categories.map((cat) {
final isActive = _selectedCategory == cat;
return GestureDetector(
onTap: () => setState(() => _selectedCategory = cat),
child: Container(
margin: const EdgeInsets.only(right: 8),
padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
decoration: BoxDecoration(color: isActive ? orange : surface, borderRadius: BorderRadius.circular(20), border: isActive ? null : Border.all(color: border)),
child: Text(cat, style: GoogleFonts.barlowCondensed(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1, color: isActive ? background : textMuted)),
),
);
}).toList(),
),
),
const SizedBox(height: 14),
if (filteredDocs.isEmpty)
Padding(
padding: const EdgeInsets.all(24),
child: Center(child: Text('No expenses yet this month.', style: GoogleFonts.barlow(fontSize: 14, color: textMuted))),
)
else
...filteredDocs.map((doc) {
final data = doc.data() as Map<String, dynamic>;
final amount = (data['amount'] ?? 0.0).toDouble();
final category = data['category'] ?? 'Other';
final note = data['note'] ?? '';
final icon = _categoryIcons[category] ?? 'O';
return Padding(
padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
child: Container(
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
child: Row(
children: [
Container(
width: 42, height: 42,
decoration: BoxDecoration(color: orange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
child: Center(child: Text(icon, style: GoogleFonts.barlowCondensed(fontSize: 14, fontWeight: FontWeight.w900, color: orange))),
),
const SizedBox(width: 12),
Expanded(
child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
Text(category, style: GoogleFonts.barlow(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
if (note.isNotEmpty) Text(note, style: GoogleFonts.barlow(fontSize: 11, color: textMuted)),
]),
),
Text('USD ' + amount.toStringAsFixed(2), style: GoogleFonts.barlowCondensed(fontSize: 18, fontWeight: FontWeight.w900, color: textPrimary)),
],
),
),
);
}),
],
);
},
),
const SizedBox(height: 24),
],
),
),
),
_buildBottomNav(context),
],
),
),
);
}
}

