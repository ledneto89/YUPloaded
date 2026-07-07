import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
const LoginPage({super.key});

@override
State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
final _emailController = TextEditingController();
final _passwordController = TextEditingController();
bool _obscurePassword = true;
bool _isLoading = false;

static const Color background = Color(0xFF0B1628);
static const Color surface = Color(0xFF122035);
static const Color border = Color(0xFF1C2E45);
static const Color orange = Color(0xFFF5921E);
static const Color textMuted = Color(0xFF5A7A9A);

@override
void dispose() {
_emailController.dispose();
_passwordController.dispose();
super.dispose();
}

Widget _buildField({
required String label,
required String hint,
required TextEditingController controller,
TextInputType keyboardType = TextInputType.text,
bool obscure = false,
Widget? suffixIcon,
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
hintStyle: GoogleFonts.barlow(fontSize: 15, color: const Color(0xFF3A5070)),
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
padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
child: Column(
crossAxisAlignment: CrossAxisAlignment.center,
children: [
const SizedBox(height: 24),
RichText(
text: TextSpan(
children: [
TextSpan(text: 'YUP', style: GoogleFonts.barlowCondensed(fontSize: 52, fontWeight: FontWeight.w900, color: orange, letterSpacing: -1, height: 1)),
TextSpan(text: 'loaded', style: GoogleFonts.barlowCondensed(fontSize: 52, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1, height: 1)),
],
),
),
const SizedBox(height: 8),
Text('Welcome back. Let\'s get rolling.', style: GoogleFonts.barlow(fontSize: 13, fontWeight: FontWeight.w500, color: textMuted), textAlign: TextAlign.center),
const SizedBox(height: 40),
_buildField(label: 'EMAIL ADDRESS', hint: 'your@email.com', controller: _emailController, keyboardType: TextInputType.emailAddress),
const SizedBox(height: 14),
_buildField(
label: 'PASSWORD',
hint: 'Your password',
controller: _passwordController,
obscure: _obscurePassword,
suffixIcon: IconButton(
icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: textMuted, size: 20),
onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
),
),
const SizedBox(height: 8),
Align(
alignment: Alignment.centerRight,
child: Text('Forgot password?', style: GoogleFonts.barlow(fontSize: 13, color: orange, fontWeight: FontWeight.w600)),
),
const SizedBox(height: 28),
SizedBox(
width: double.infinity,
height: 56,
child: ElevatedButton(
onPressed: _isLoading ? null : () async {
setState(() => _isLoading = true);
try {
await FirebaseAuth.instance.signInWithEmailAndPassword(
email: _emailController.text.trim(),
password: _passwordController.text.trim(),
);
if (mounted) {
Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
}
} catch (e) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Invalid email or password'), backgroundColor: Colors.red),
);
}
} finally {
if (mounted) setState(() => _isLoading = false);
}
},
style: ElevatedButton.styleFrom(backgroundColor: orange, foregroundColor: background, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
child: _isLoading
? const CircularProgressIndicator(color: Colors.white)
: Text('SIGN IN', style: GoogleFonts.barlowCondensed(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2, color: background)),
),
),
const SizedBox(height: 24),
Row(
children: [
Expanded(child: Container(height: 1, color: border)),
Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('or', style: GoogleFonts.barlow(fontSize: 13, color: textMuted))),
Expanded(child: Container(height: 1, color: border)),
],
),
const SizedBox(height: 24),
Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Text('Don\'t have an account? ', style: GoogleFonts.barlow(fontSize: 13, color: textMuted, fontWeight: FontWeight.w500)),
GestureDetector(
onTap: () => Navigator.pop(context),
child: Text('Sign up', style: GoogleFonts.barlow(fontSize: 13, color: orange, fontWeight: FontWeight.w600)),
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
