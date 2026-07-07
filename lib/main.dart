import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'loads_page.dart';
import 'new_load_page.dart';
import 'quick_details_page.dart';
import 'yuploaded_page.dart';
import 'expenses_page.dart';
import 'add_expense_page.dart';
import 'taxes_page.dart';
import 'profile_page.dart';
import 'payment_page.dart';

void main() async {
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(
options: DefaultFirebaseOptions.currentPlatform,
);
runApp(const YUPLOADEDApp());
}

class YUPLOADEDApp extends StatelessWidget {
const YUPLOADEDApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
title: 'YUPLOADED',
debugShowCheckedModeBanner: false,
theme: ThemeData(
scaffoldBackgroundColor: const Color(0xFF0B1628),
),
builder: (context, child) {
return Center(
child: ConstrainedBox(
constraints: const BoxConstraints(maxWidth: 430),
child: child!,
),
);
},
home: const RegisterPage(),
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
final _mcDotController = TextEditingController();
bool _obscurePassword = true;
bool _isLoading = false;
String? _selectedEquipment;

static const Color background = Color(0xFF0B1628);
static const Color surface = Color(0xFF122035);
static const Color border = Color(0xFF1C2E45);
static const Color orange = Color(0xFFF5921E);
static const Color textPrimary = Color(0xFFFFFFFF);
static const Color textMuted = Color(0xFF5A7A9A);

final List<Map<String, String>> _equipmentTypes = [
{'emoji': '🚛', 'label': '53ft Dry Van'},
{'emoji': '🧊', 'label': 'Reefer'},
{'emoji': '🏗️', 'label': 'Flatbed'},
{'emoji': '💧', 'label': 'Tanker'},
{'emoji': '⚡', 'label': 'Sprinter / Cargo Van'},
{'emoji': '🔥', 'label': 'Hotshot'},
{'emoji': '🚗', 'label': 'Car Hauler'},
{'emoji': '🏋️', 'label': 'Heavy Haul'},
{'emoji': '📦', 'label': 'Box Truck'},
{'emoji': '🚚', 'label': 'Other'},
];

@override
void dispose() {
_firstNameController.dispose();
_lastNameController.dispose();
_emailController.dispose();
_passwordController.dispose();
_mcDotController.dispose();
super.dispose();
}

Widget _buildField({
required String label,
required String hint,
required TextEditingController controller,
TextInputType keyboardType = TextInputType.text,
bool obscure = false,
Widget? suffixIcon,
Color? hintColor,
}) {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(label, style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: textMuted)),
const SizedBox(height: 6),
TextField(
controller: controller,
keyboardType: keyboardType,
obscureText: obscure,
style: GoogleFonts.barlow(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
decoration: InputDecoration(
hintText: hint,
hintStyle: GoogleFonts.barlow(fontSize: 15, color: hintColor ?? const Color(0xFF3A5070)),
suffixIcon: suffixIcon,
filled: true,
fillColor: surface,
contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1C2E45), width: 1.5)),
focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF5921E), width: 1.5)),
),
),
],
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: background,
body: SafeArea(
child: SingleChildScrollView(
padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
child: Column(
crossAxisAlignment: CrossAxisAlignment.center,
children: [
RichText(
text: TextSpan(
children: [
TextSpan(text: 'YUP', style: GoogleFonts.barlowCondensed(fontSize: 52, fontWeight: FontWeight.w900, color: orange, letterSpacing: -1, height: 1)),
TextSpan(text: 'loaded', style: GoogleFonts.barlowCondensed(fontSize: 52, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1, height: 1)),
],
),
),
const SizedBox(height: 8),
Text('Built for the cab. Not the corner office.', style: GoogleFonts.barlow(fontSize: 13, fontWeight: FontWeight.w500, color: textMuted), textAlign: TextAlign.center),
const SizedBox(height: 32),
Row(
children: [
Expanded(child: _buildField(label: 'FIRST NAME', hint: 'Mike', controller: _firstNameController)),
const SizedBox(width: 12),
Expanded(child: _buildField(label: 'LAST NAME', hint: 'Torres', controller: _lastNameController)),
],
),
const SizedBox(height: 14),
_buildField(label: 'EMAIL ADDRESS', hint: 'your@email.com', controller: _emailController, keyboardType: TextInputType.emailAddress),
const SizedBox(height: 14),
_buildField(
label: 'CREATE PASSWORD',
hint: 'Create a password',
controller: _passwordController,
obscure: _obscurePassword,
suffixIcon: IconButton(
icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: textMuted, size: 20),
onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
),
),
const SizedBox(height: 14),
_buildField(label: 'MC / DOT NUMBER', hint: 'Optional - add later', controller: _mcDotController, hintColor: textMuted),
const SizedBox(height: 14),
Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('WHAT DO YOU DRIVE?', style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: textMuted)),
const SizedBox(height: 8),
GridView.builder(
shrinkWrap: true,
physics: const NeverScrollableScrollPhysics(),
gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 3.2),
itemCount: _equipmentTypes.length,
itemBuilder: (context, i) {
final eq = _equipmentTypes[i];
final isSelected = _selectedEquipment == eq['label'];
return GestureDetector(
onTap: () => setState(() => _selectedEquipment = eq['label']),
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
decoration: BoxDecoration(color: isSelected ? orange : surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: isSelected ? orange : border, width: 1.5)),
child: Row(
children: [
Text(eq['emoji']!, style: const TextStyle(fontSize: 16)),
const SizedBox(width: 8),
Expanded(child: Text(eq['label']!, style: GoogleFonts.barlowCondensed(fontSize: 13, fontWeight: FontWeight.w800, color: isSelected ? background : textPrimary), overflow: TextOverflow.ellipsis)),
],
),
),
);
},
),
],
),
const SizedBox(height: 28),
SizedBox(
width: double.infinity,
height: 56,
child: ElevatedButton(
onPressed: _isLoading ? null : () async {
setState(() => _isLoading = true);
try {
final credential = await FirebaseAuth.instance
.createUserWithEmailAndPassword(
email: _emailController.text.trim(),
password: _passwordController.text.trim(),
);
await FirebaseFirestore.instance
.collection('users')
.doc(credential.user!.uid)
.set({
'firstName': _firstNameController.text.trim(),
'lastName': _lastNameController.text.trim(),
'email': _emailController.text.trim(),
'mcDot': _mcDotController.text.trim(),
'equipmentType': _selectedEquipment ?? '',
'totalLoads': 0,
'dispatcherEmail': '',
'plan': 'trial',
'createdAt': FieldValue.serverTimestamp(),
});
if (mounted) {
Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PaymentPage()));
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
},
style: ElevatedButton.styleFrom(backgroundColor: orange, foregroundColor: background, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
child: _isLoading
? const CircularProgressIndicator(color: Colors.white)
: Text('CREATE ACCOUNT', style: GoogleFonts.barlowCondensed(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2, color: background)),
),
),
const SizedBox(height: 20),
Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Text('Already have an account? ', style: GoogleFonts.barlow(fontSize: 13, color: textMuted, fontWeight: FontWeight.w500)),
GestureDetector(
onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())),
child: Text('Sign in', style: GoogleFonts.barlow(fontSize: 13, color: orange, fontWeight: FontWeight.w600)),
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
}