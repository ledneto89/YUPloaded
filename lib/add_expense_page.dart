import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddExpensePage extends StatefulWidget {
const AddExpensePage({super.key});

@override
State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
final _amountController = TextEditingController();
final _noteController = TextEditingController();
String? _selectedCategory;
bool _isLoading = false;

static const Color background = Color(0xFF0B1628);
static const Color surface = Color(0xFF122035);
static const Color border = Color(0xFF1C2E45);
static const Color orange = Color(0xFFF5921E);
static const Color textPrimary = Color(0xFFFFFFFF);
static const Color textMuted = Color(0xFF5A7A9A);
static const Color success = Color(0xFF4ADE80);

final List<Map<String, String>> _categories = [
{'icon': '⛽', 'label': 'Fuel'},
{'icon': '🔧', 'label': 'Repairs'},
{'icon': '🛣️', 'label': 'Tolls'},
{'icon': '📋', 'label': 'Permits'},
{'icon': '🏨', 'label': 'Lodging'},
{'icon': '👷', 'label': 'Lumper'},
{'icon': '📦', 'label': 'Other'},
];

Future<void> _saveExpense() async {
if (_amountController.text.isEmpty || _selectedCategory == null) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Please enter amount and select category'), backgroundColor: Colors.red),
);
return;
}

setState(() => _isLoading = true);
try {
final user = FirebaseAuth.instance.currentUser;
if (user == null) return;

await FirebaseFirestore.instance.collection('expenses').add({
'userId': user.uid,
'amount': double.tryParse(_amountController.text.replaceAll('\$', '')) ?? 0.0,
'category': _selectedCategory,
'note': _noteController.text.trim(),
'date': FieldValue.serverTimestamp(),
'createdAt': FieldValue.serverTimestamp(),
});

if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('✓ YUPLOADED. Expense saved.'),
backgroundColor: Color(0xFF4ADE80),
),
);
Navigator.pop(context);
}
} catch (e) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
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
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
GestureDetector(
onTap: () => Navigator.pop(context),
child: Container(width: 34, height: 34, decoration: BoxDecoration(color: surface, shape: BoxShape.circle), child: const Center(child: Text('‹', style: TextStyle(color: Colors.white, fontSize: 22)))),
),
const SizedBox(width: 12),
Text('New Expense', style: GoogleFonts.barlowCondensed(fontSize: 24, fontWeight: FontWeight.w900, color: textPrimary)),
],
),
const SizedBox(height: 20),

// AMOUNT
Text('AMOUNT', style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: textMuted)),
const SizedBox(height: 6),
TextField(
controller: _amountController,
keyboardType: const TextInputType.numberWithOptions(decimal: true),
style: GoogleFonts.barlowCondensed(fontSize: 36, fontWeight: FontWeight.w900, color: orange),
decoration: InputDecoration(
hintText: '0.00',
hintStyle: GoogleFonts.barlowCondensed(fontSize: 36, color: const Color(0xFF2A4060)),
prefixText: '\$',
prefixStyle: GoogleFonts.barlowCondensed(fontSize: 36, fontWeight: FontWeight.w900, color: orange),
filled: true,
fillColor: surface,
contentPadding: const EdgeInsets.all(14),
enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF5921E), width: 1.5)),
focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF5921E), width: 1.5)),
),
),

const SizedBox(height: 20),

// CATEGORY
Text('CATEGORY', style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: textMuted)),
const SizedBox(height: 8),
GridView.builder(
shrinkWrap: true,
physics: const NeverScrollableScrollPhysics(),
gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.2),
itemCount: _categories.length,
itemBuilder: (context, i) {
final cat = _categories[i];
final isSelected = _selectedCategory == cat['label'];
return GestureDetector(
onTap: () => setState(() => _selectedCategory = cat['label']),
child: Container(
decoration: BoxDecoration(color: isSelected ? orange : surface, borderRadius: BorderRadius.circular(10), border: isSelected ? null : Border.all(color: border)),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Text(cat['icon']!, style: const TextStyle(fontSize: 20)),
const SizedBox(height: 4),
Text(cat['label']!, style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w800, color: isSelected ? background : textMuted)),
],
),
),
);
},
),

const SizedBox(height: 16),

// NOTE
Text('NOTE (OPTIONAL)', style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: textMuted)),
const SizedBox(height: 6),
TextField(
controller: _noteController,
style: GoogleFonts.barlow(fontSize: 14, color: textPrimary),
decoration: InputDecoration(
hintText: 'Station name, location, notes...',
hintStyle: GoogleFonts.barlow(fontSize: 14, color: const Color(0xFF3A5070)),
filled: true,
fillColor: surface,
contentPadding: const EdgeInsets.all(14),
enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1C2E45), width: 1.5)),
focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF5921E), width: 1.5)),
),
),

const SizedBox(height: 16),

// RECEIPT UPLOAD
Container(
decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
child: Column(
children: [
Padding(
padding: const EdgeInsets.all(14),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('RECEIPT', style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: textMuted)),
const SizedBox(height: 4),
Text('Got a receipt photo? Upload it for your records.', style: GoogleFonts.barlow(fontSize: 13, color: const Color(0xFF7A95B0))),
],
),
),
const Divider(height: 1, color: Color(0xFF1C2E45)),
Row(
children: [
Expanded(
child: GestureDetector(
onTap: () {},
child: Container(
padding: const EdgeInsets.symmetric(vertical: 14),
decoration: const BoxDecoration(color: Color(0xFFF5921E), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12))),
child: Center(child: Text('📁 YUPLOAD', style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0B1628), letterSpacing: 2))),
),
),
),
Expanded(
child: GestureDetector(
onTap: () {},
child: Container(
padding: const EdgeInsets.symmetric(vertical: 14),
decoration: const BoxDecoration(borderRadius: BorderRadius.only(bottomRight: Radius.circular(12))),
child: Center(child: Text('NOPE', style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF5A7A9A), letterSpacing: 2))),
),
),
),
],
),
],
),
),

const SizedBox(height: 16),

// SAVE BUTTON
SizedBox(
width: double.infinity,
height: 56,
child: ElevatedButton(
onPressed: _isLoading ? null : _saveExpense,
style: ElevatedButton.styleFrom(backgroundColor: orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
child: _isLoading
? const CircularProgressIndicator(color: Colors.white)
: Text('↑ YUPLOAD', style: GoogleFonts.barlowCondensed(fontSize: 22, fontWeight: FontWeight.w900, color: background, letterSpacing: 3)),
),
),

const SizedBox(height: 24),
],
),
),
),
);
}
}
