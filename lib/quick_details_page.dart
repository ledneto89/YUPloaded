import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'yuploaded_page.dart';
import 'invoice_generator.dart';
import 'email_service.dart';
import 'payment_page.dart';

class QuickDetailsPage extends StatefulWidget {
const QuickDetailsPage({super.key});

@override
State<QuickDetailsPage> createState() => _QuickDetailsPageState();
}

class _QuickDetailsPageState extends State<QuickDetailsPage> {
final _mileageController = TextEditingController();
final _expensesController = TextEditingController();
final _notesController = TextEditingController();
final _brokerEmailController = TextEditingController();
final _rateController = TextEditingController();
String? _pickupState;
String? _deliveryState;
bool _isLoading = false;

static const Color background = Color(0xFF0B1628);
static const Color surface = Color(0xFF122035);
static const Color border = Color(0xFF1C2E45);
static const Color orange = Color(0xFFF5921E);
static const Color textPrimary = Color(0xFFFFFFFF);
static const Color textMuted = Color(0xFF5A7A9A);
static const Color success = Color(0xFF4ADE80);
static const Color danger = Color(0xFFEF4444);

final List<String> _states = ['AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA','HI','ID','IL','IN','IA','KS','KY','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ','NM','NY','NC','ND','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VT','VA','WA','WV','WI','WY'];

Future<bool> _checkFreeLimit() async {
final user = FirebaseAuth.instance.currentUser;
if (user == null) return false;

final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
final userData = userDoc.data() ?? {};
final isFree = userData['isFree'] ?? true;
final totalLoads = (userData['totalLoads'] ?? 0) as int;

if (isFree && totalLoads >= 3) {
if (mounted) {
showDialog(
context: context,
builder: (ctx) => AlertDialog(
backgroundColor: surface,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
title: Text('Free limit reached', style: GoogleFonts.barlowCondensed(fontSize: 22, fontWeight: FontWeight.w900, color: textPrimary)),
content: Text('You have used your 3 free loads. Upgrade to Pro for unlimited loads at USD 19 per month.', style: GoogleFonts.barlow(fontSize: 14, color: textMuted)),
actions: [
TextButton(
onPressed: () => Navigator.pop(ctx),
child: Text('NOPE', style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w900, color: textMuted, letterSpacing: 1)),
),
TextButton(
onPressed: () {
Navigator.pop(ctx);
Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentPage()));
},
child: Text('UPGRADE - YUP', style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w900, color: orange, letterSpacing: 1)),
),
],
),
);
}
return false;
}
return true;
}

Future<void> _yupload() async {
final canUpload = await _checkFreeLimit();
if (!canUpload) return;

setState(() => _isLoading = true);
try {
final user = FirebaseAuth.instance.currentUser;
if (user == null) return;

final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
final userData = userDoc.data() ?? {};
final totalLoads = (userData['totalLoads'] ?? 0) as int;
final loadNumber = 'YU-' + (totalLoads + 1).toString().padLeft(4, '0');
final firstName = userData['firstName'] ?? 'Driver';
final lastName = userData['lastName'] ?? '';
final driverName = firstName + ' ' + lastName;
final mcNumber = userData['mcDot'] ?? '';
final dispatcherEmail = userData['dispatcherEmail'] ?? '';
final rate = double.tryParse(_rateController.text.replaceAll(',', '')) ?? 0.0;
final brokerEmail = _brokerEmailController.text.trim();

await FirebaseFirestore.instance.collection('loads').add({
'userId': user.uid,
'loadNumber': loadNumber,
'mileage': int.tryParse(_mileageController.text) ?? 0,
'expenses': double.tryParse(_expensesController.text.replaceAll(',', '')) ?? 0.0,
'pickupState': _pickupState ?? '',
'deliveryState': _deliveryState ?? '',
'notes': _notesController.text.trim(),
'brokerEmail': brokerEmail,
'rate': rate,
'status': 'invoiced',
'createdAt': FieldValue.serverTimestamp(),
});

await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
'totalLoads': FieldValue.increment(1),
});

if (brokerEmail.isNotEmpty) {
await EmailService.sendInvoice(
brokerEmail: brokerEmail,
loadNumber: loadNumber,
pickupState: _pickupState ?? '',
deliveryState: _deliveryState ?? '',
rate: 'USD ' + rate.toStringAsFixed(2),
driverName: driverName,
mcNumber: mcNumber,
);
}

if (dispatcherEmail.isNotEmpty) {
await EmailService.sendDispatcherPacket(
dispatcherEmail: dispatcherEmail,
loadNumber: loadNumber,
pickupState: _pickupState ?? '',
deliveryState: _deliveryState ?? '',
driverName: driverName,
);
}

if (mounted) {
await InvoiceGenerator.generateAndShare(
loadNumber: loadNumber,
driverName: driverName,
mcNumber: mcNumber,
pickupState: _pickupState ?? '',
deliveryState: _deliveryState ?? '',
rate: rate,
brokerEmail: brokerEmail,
context: context,
);

Navigator.pushReplacement(
context,
MaterialPageRoute(builder: (_) => YUPLOADEDPage(loadNumber: loadNumber)),
);
}
} catch (e) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Error: ' + e.toString()), backgroundColor: danger),
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
child: Container(width: 34, height: 34, decoration: BoxDecoration(color: surface, shape: BoxShape.circle), child: const Center(child: Icon(Icons.chevron_left, color: Colors.white))),
),
const SizedBox(width: 12),
Text('Quick Details', style: GoogleFonts.barlowCondensed(fontSize: 24, fontWeight: FontWeight.w900, color: textPrimary)),
],
),
const SizedBox(height: 16),
Row(children: List.generate(5, (i) => Expanded(child: Container(height: 4, margin: const EdgeInsets.only(right: 6), decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(2)))))),
const SizedBox(height: 16),
Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(color: success.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: success.withValues(alpha: 0.2))),
child: Row(children: [const Icon(Icons.check_circle, color: Color(0xFF4ADE80), size: 16), const SizedBox(width: 8), Text('All docs uploaded - almost there', style: GoogleFonts.barlow(fontSize: 13, color: success, fontWeight: FontWeight.w600))]),
),
const SizedBox(height: 16),
_buildDetailField('RATE (USD)', '0', _rateController, TextInputType.number),
const SizedBox(height: 10),
Row(
children: [
Expanded(child: _buildDetailField('MILEAGE', '0', _mileageController, TextInputType.number)),
const SizedBox(width: 10),
Expanded(child: _buildDetailField('EXPENSES', '0', _expensesController, TextInputType.number, hint: 'Fuel tolls lumper')),
],
),
const SizedBox(height: 10),
Row(
children: [
Expanded(child: _buildStateDropdown('PICK UP STATE', _pickupState, (val) => setState(() => _pickupState = val))),
const SizedBox(width: 10),
Expanded(child: _buildStateDropdown('DELIVERY STATE', _deliveryState, (val) => setState(() => _deliveryState = val))),
],
),
const SizedBox(height: 10),
Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('NOTES (OPTIONAL)', style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: textMuted)),
const SizedBox(height: 6),
TextField(
controller: _notesController,
maxLines: 3,
style: GoogleFonts.barlow(fontSize: 14, color: textPrimary),
decoration: InputDecoration(hintText: 'Anything worth remembering about this load...', hintStyle: GoogleFonts.barlow(fontSize: 13, color: const Color(0xFF3A5070)), filled: true, fillColor: surface, contentPadding: const EdgeInsets.all(14), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1C2E45), width: 1.5)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF5921E), width: 1.5))),
),
],
),
const SizedBox(height: 10),
Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('BROKER EMAIL', style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: textMuted)),
const SizedBox(height: 6),
TextField(
controller: _brokerEmailController,
keyboardType: TextInputType.emailAddress,
style: GoogleFonts.barlow(fontSize: 14, color: textPrimary),
decoration: InputDecoration(hintText: 'broker@company.com', hintStyle: GoogleFonts.barlow(fontSize: 13, color: const Color(0xFF3A5070)), filled: true, fillColor: surface, contentPadding: const EdgeInsets.all(14), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1C2E45), width: 1.5)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF5921E), width: 1.5))),
),
],
),
const SizedBox(height: 14),
SizedBox(
width: double.infinity,
height: 64,
child: ElevatedButton(
onPressed: _isLoading ? null : _yupload,
style: ElevatedButton.styleFrom(backgroundColor: orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
child: _isLoading
? const CircularProgressIndicator(color: Colors.white)
: Text('YUPLOAD', style: GoogleFonts.barlowCondensed(fontSize: 26, fontWeight: FontWeight.w900, color: background, letterSpacing: 3)),
),
),
const SizedBox(height: 8),
Center(child: Text('Saves load - emails broker - generates invoice', style: GoogleFonts.barlow(fontSize: 11, color: textMuted))),
const SizedBox(height: 24),
],
),
),
),
);
}

Widget _buildDetailField(String label, String placeholder, TextEditingController controller, TextInputType type, {String? hint}) {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(label, style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: orange)),
const SizedBox(height: 6),
TextField(
controller: controller,
keyboardType: type,
style: GoogleFonts.barlowCondensed(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimary),
decoration: InputDecoration(hintText: hint ?? placeholder, hintStyle: GoogleFonts.barlow(fontSize: 13, color: const Color(0xFF3A5070)), filled: true, fillColor: surface, contentPadding: const EdgeInsets.all(14), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1C2E45), width: 1.5)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF5921E), width: 1.5))),
),
],
);
}

Widget _buildStateDropdown(String label, String? value, Function(String?) onChanged) {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(label, style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: orange)),
const SizedBox(height: 6),
Container(
padding: const EdgeInsets.symmetric(horizontal: 14),
decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border, width: 1.5)),
child: DropdownButtonHideUnderline(
child: DropdownButton<String>(
value: value,
hint: Text('State', style: GoogleFonts.barlow(fontSize: 14, color: const Color(0xFF3A5070))),
dropdownColor: surface,
style: GoogleFonts.barlowCondensed(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimary),
isExpanded: true,
items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
onChanged: onChanged,
),
),
),
],
);
}
}