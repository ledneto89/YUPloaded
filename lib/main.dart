import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'home_page.dart';
import 'login_page.dart';
import 'payment_page.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
runApp(const YUPLOADEDApp());
}

class YUPLOADEDApp extends StatelessWidget {
const YUPLOADEDApp({super.key});
@override
Widget build(BuildContext context) {
return MaterialApp(
title: 'YUPloaded',
debugShowCheckedModeBanner: false,
theme: ThemeData(scaffoldBackgroundColor: const Color(0xFF0B1628), colorScheme: ColorScheme.dark(primary: const Color(0xFFF5921E))),
home: StreamBuilder<User?>(
stream: FirebaseAuth.instance.authStateChanges(),
builder: (context, snapshot) {
if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFF5921E))));
if (snapshot.hasData) return const HomePage();
return const RegisterPage();
},
),
);
}
}

class RegisterPage extends StatefulWidget {
const RegisterPage({super.key});
@override
State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
final _firstNameController = TextEditingController();
final _lastNameController = TextEditingController();
final _emailController = TextEditingController();
final _passwordController = TextEditingController();
final _mcController = TextEditingController();
String? _equipmentType;
String? _licenseUrl;
bool _isLoading = false;
bool _isUploadingLicense = false;

static const Color background = Color(0xFF0B1628);
static const Color surface = Color(0xFF122035);
static const Color border = Color(0xFF1C2E45);
static const Color orange = Color(0xFFF5921E);
static const Color textPrimary = Color(0xFFFFFFFF);
static const Color textMuted = Color(0xFF5A7A9A);
static const Color success = Color(0xFF4ADE80);
static const Color danger = Color(0xFFEF4444);

final List<String> _equipmentTypes = ['Dry Van 53ft', 'Reefer 53ft', 'Flatbed', 'Step Deck', 'RGN', 'Tanker', 'Power Only', 'Sprinter Van', 'Box Truck', 'Car Hauler', 'Other'];

Future<void> _uploadLicense() async {
try {
final picker = ImagePicker();
final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
if (picked == null) return;
setState(() => _isUploadingLicense = true);
final fileName = 'license_' + DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
final ref = FirebaseStorage.instance.ref().child('licenses/temp/' + fileName);
await ref.putFile(File(picked.path));
final url = await ref.getDownloadURL();
setState(() { _licenseUrl = url; _isUploadingLicense = false; });
} catch (e) {
setState(() => _isUploadingLicense = false);
}
}

bool _validateMC(String mc) {
final cleaned = mc.replaceAll(RegExp(r'[^0-9]'), '');
return cleaned.length >= 6 && cleaned.length <= 8;
}

Future<void> _register() async {
if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your full name'), backgroundColor: Color(0xFFEF4444)));
return;
}
if (_mcController.text.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('MC number is required'), backgroundColor: Color(0xFFEF4444)));
return;
}
if (!_validateMC(_mcController.text)) {
ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid MC number'), backgroundColor: Color(0xFFEF4444)));
return;
}
if (_licenseUrl == null) {
ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Driver license photo is required'), backgroundColor: Color(0xFFEF4444)));
return;
}
if (_equipmentType == null) {
ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select your equipment type'), backgroundColor: Color(0xFFEF4444)));
return;
}
if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter email and password'), backgroundColor: Color(0xFFEF4444)));
return;
}

setState(() => _isLoading = true);
try {
final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
email: _emailController.text.trim(),
password: _passwordController.text,
);

final uid = credential.user!.uid;

// Move license to user folder
if (_licenseUrl != null) {
final ref = FirebaseStorage.instance.ref().child('licenses/' + uid + '/license.jpg');
// License already uploaded to temp, just update the path reference
}

await FirebaseFirestore.instance.collection('users').doc(uid).set({
'firstName': _firstNameController.text.trim(),
'lastName': _lastNameController.text.trim(),
'email': _emailController.text.trim(),
'mcDot': _mcController.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
'equipmentType': _equipmentType,
'licenseUrl': _licenseUrl ?? '',
'licenseVerified': false,
'totalLoads': 0,
'verifiedLoads': 0,
'isFree': true,
'plan': 'FREE',
'createdAt': FieldValue.serverTimestamp(),
});

if (mounted) {
Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PaymentPage()));
}
} on FirebaseAuthException catch (e) {
String message = 'Registration failed';
if (e.code == 'weak-password') message = 'Password must be at least 6 characters';
if (e.code == 'email-already-in-use') message = 'An account already exists with this email';
if (e.code == 'invalid-email') message = 'Please enter a valid email address';
if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: danger));
} finally {
if (mounted) setState(() => _isLoading = false);
}
}

Widget _buildField(String label, TextEditingController controller, {TextInputType type = TextInputType.text, bool obscure = false, String? hint}) {
return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
Text(label, style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: textMuted)),
const SizedBox(height: 6),
TextField(
controller: controller,
keyboardType: type,
obscureText: obscure,
style: GoogleFonts.barlow(fontSize: 14, color: textPrimary),
decoration: InputDecoration(
hintText: hint,
hintStyle: GoogleFonts.barlow(fontSize: 13, color: const Color(0xFF3A5070)),
filled: true, fillColor: surface, contentPadding: const EdgeInsets.all(14),
enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1C2E45), width: 1.5)),
focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF5921E), width: 1.5)),
),
),
]);
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: background,
body: SafeArea(
child: SingleChildScrollView(
padding: const EdgeInsets.all(24),
child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
const SizedBox(height: 20),
Text('YUP', style: GoogleFonts.barlowCondensed(fontSize: 52, fontWeight: FontWeight.w900, color: orange, letterSpacing: -2, height: 1)),
Text('loaded', style: GoogleFonts.barlowCondensed(fontSize: 36, fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: -1, height: 1)),
const SizedBox(height: 8),
Text('Snap. Invoice. Get Paid.', style: GoogleFonts.barlow(fontSize: 14, color: textMuted)),
const SizedBox(height: 32),

Text('CREATE ACCOUNT', style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: textMuted)),
const SizedBox(height: 16),

Row(children: [
Expanded(child: _buildField('FIRST NAME', _firstNameController, hint: 'John')),
const SizedBox(width: 12),
Expanded(child: _buildField('LAST NAME', _lastNameController, hint: 'Smith')),
]),
const SizedBox(height: 12),

// MC NUMBER - REQUIRED
Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
Row(children: [
Text('MC NUMBER', style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: textMuted)),
const SizedBox(width: 8),
Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: danger.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)), child: Text('REQUIRED', style: GoogleFonts.barlowCondensed(fontSize: 9, fontWeight: FontWeight.w900, color: danger, letterSpacing: 1))),
]),
const SizedBox(height: 6),
TextField(
controller: _mcController,
keyboardType: TextInputType.number,
style: GoogleFonts.barlow(fontSize: 14, color: textPrimary),
decoration: InputDecoration(
hintText: 'MC number (numbers only)',
hintStyle: GoogleFonts.barlow(fontSize: 13, color: const Color(0xFF3A5070)),
prefixText: 'MC-',
prefixStyle: GoogleFonts.barlow(fontSize: 14, color: orange, fontWeight: FontWeight.w600),
filled: true, fillColor: surface, contentPadding: const EdgeInsets.all(14),
enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1C2E45), width: 1.5)),
focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF5921E), width: 1.5)),
),
),
const SizedBox(height: 4),
Text('Your FMCSA Motor Carrier number', style: GoogleFonts.barlow(fontSize: 10, color: textMuted)),
]),
const SizedBox(height: 12),

// DRIVER LICENSE UPLOAD - REQUIRED
Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
Row(children: [
Text('DRIVER LICENSE', style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: textMuted)),
const SizedBox(width: 8),
Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: danger.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)), child: Text('REQUIRED', style: GoogleFonts.barlowCondensed(fontSize: 9, fontWeight: FontWeight.w900, color: danger, letterSpacing: 1))),
]),
const SizedBox(height: 6),
GestureDetector(
onTap: _isUploadingLicense ? null : _uploadLicense,
child: Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: surface,
borderRadius: BorderRadius.circular(12),
border: Border.all(color: _licenseUrl != null ? success : border, width: 1.5),
),
child: Row(children: [
Icon(_licenseUrl != null ? Icons.check_circle : Icons.badge, color: _licenseUrl != null ? success : textMuted, size: 24),
const SizedBox(width: 12),
Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
Text(_licenseUrl != null ? 'License uploaded' : 'Upload driver license photo', style: GoogleFonts.barlow(fontSize: 14, color: _licenseUrl != null ? success : textPrimary, fontWeight: FontWeight.w500)),
Text('Verifies your identity as a licensed driver', style: GoogleFonts.barlow(fontSize: 11, color: textMuted)),
])),
if (_isUploadingLicense) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFFF5921E), strokeWidth: 2))
else Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: _licenseUrl != null ? success.withValues(alpha: 0.12) : orange, borderRadius: BorderRadius.circular(8)), child: Text(_licenseUrl != null ? 'REPLACE' : 'UPLOAD', style: GoogleFonts.barlowCondensed(fontSize: 12, fontWeight: FontWeight.w900, color: _licenseUrl != null ? success : background))),
]),
),
),
]),
const SizedBox(height: 12),

// EQUIPMENT TYPE
Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
Text('EQUIPMENT TYPE', style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: textMuted)),
const SizedBox(height: 6),
Container(
padding: const EdgeInsets.symmetric(horizontal: 14),
decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border, width: 1.5)),
child: DropdownButtonHideUnderline(child: DropdownButton<String>(
value: _equipmentType,
hint: Text('Select equipment type', style: GoogleFonts.barlow(fontSize: 14, color: const Color(0xFF3A5070))),
dropdownColor: surface, style: GoogleFonts.barlow(fontSize: 14, color: textPrimary), isExpanded: true,
items: _equipmentTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
onChanged: (val) => setState(() => _equipmentType = val),
)),
),
]),
const SizedBox(height: 12),

_buildField('EMAIL', _emailController, type: TextInputType.emailAddress, hint: 'your@email.com'),
const SizedBox(height: 12),
_buildField('PASSWORD', _passwordController, obscure: true, hint: 'Minimum 6 characters'),
const SizedBox(height: 24),

// VERIFIED PREVIEW
Container(
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: orange.withValues(alpha: 0.3))),
child: Row(children: [
const Icon(Icons.shield, color: Color(0xFFF5921E), size: 20),
const SizedBox(width: 12),
Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
Text('Road to YUPLOADED Verified', style: GoogleFonts.barlowCondensed(fontSize: 13, fontWeight: FontWeight.w800, color: textPrimary)),
Text('Complete 100 broker-confirmed loads to earn your verified badge. Earned. Not bought.', style: GoogleFonts.barlow(fontSize: 11, color: textMuted)),
])),
]),
),
const SizedBox(height: 20),

SizedBox(
width: double.infinity, height: 56,
child: ElevatedButton(
onPressed: _isLoading ? null : _register,
style: ElevatedButton.styleFrom(backgroundColor: orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text('CREATE ACCOUNT', style: GoogleFonts.barlowCondensed(fontSize: 18, fontWeight: FontWeight.w900, color: background, letterSpacing: 2)),
),
),
const SizedBox(height: 16),
Center(
child: GestureDetector(
onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())),
child: RichText(text: TextSpan(children: [
TextSpan(text: 'Already have an account? ', style: GoogleFonts.barlow(fontSize: 14, color: textMuted)),
TextSpan(text: 'Sign In', style: GoogleFonts.barlow(fontSize: 14, color: orange, fontWeight: FontWeight.w600)),
])),
),
),
const SizedBox(height: 24),
]),
),
),
);
}
}