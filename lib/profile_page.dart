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

class ProfilePage extends StatefulWidget {
const ProfilePage({super.key});
@override
State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
bool _isUploadingPhoto = false;

static const Color background = Color(0xFF0B1628);
static const Color surface = Color(0xFF122035);
static const Color border = Color(0xFF1C2E45);
static const Color orange = Color(0xFFF5921E);
static const Color textPrimary = Color(0xFFFFFFFF);
static const Color textMuted = Color(0xFF5A7A9A);
static const Color success = Color(0xFF4ADE80);
static const Color danger = Color(0xFFEF4444);

Future<void> _uploadProfilePhoto(String uid) async {
try {
final picker = ImagePicker();
final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
if (picked == null) return;
setState(() => _isUploadingPhoto = true);
final ref = FirebaseStorage.instance.ref().child('profiles/' + uid + '/avatar.jpg');
await ref.putFile(File(picked.path));
final url = await ref.getDownloadURL();
await FirebaseFirestore.instance.collection('users').doc(uid).update({'photoUrl': url});
setState(() => _isUploadingPhoto = false);
} catch (e) {
setState(() => _isUploadingPhoto = false);
}
}

// Only dispatcher email is editable
Future<void> _editDispatcherEmail(BuildContext context, String currentValue, String uid) async {
final controller = TextEditingController(text: currentValue);
await showDialog(
context: context,
builder: (ctx) => AlertDialog(
backgroundColor: surface,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
title: Text('Update Dispatcher Email', style: GoogleFonts.barlowCondensed(fontSize: 20, fontWeight: FontWeight.w900, color: textPrimary)),
content: TextField(
controller: controller,
keyboardType: TextInputType.emailAddress,
style: GoogleFonts.barlow(fontSize: 14, color: textPrimary),
decoration: InputDecoration(filled: true, fillColor: background, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1C2E45))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFF5921E)))),
),
actions: [
TextButton(onPressed: () => Navigator.pop(ctx), child: Text('NOPE', style: GoogleFonts.barlowCondensed(fontSize: 15, fontWeight: FontWeight.w900, color: textMuted))),
TextButton(
onPressed: () async {
await FirebaseFirestore.instance.collection('users').doc(uid).update({'dispatcherEmail': controller.text.trim()});
if (ctx.mounted) Navigator.pop(ctx);
},
child: Text('YUP', style: GoogleFonts.barlowCondensed(fontSize: 15, fontWeight: FontWeight.w900, color: orange)),
),
],
),
);
}

Future<void> _deleteAccount(BuildContext context, String uid) async {
final passwordController = TextEditingController();

// Step 1 - confirm intent
final confirmed = await showDialog<bool>(
context: context,
builder: (ctx) => AlertDialog(
backgroundColor: surface,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
title: Text('Delete Account', style: GoogleFonts.barlowCondensed(fontSize: 22, fontWeight: FontWeight.w900, color: danger)),
content: Column(mainAxisSize: MainAxisSize.min, children: [
Text('This will permanently delete your account, all your loads, documents, and verified history. This cannot be undone.', style: GoogleFonts.barlow(fontSize: 14, color: textMuted, height: 1.6)),
const SizedBox(height: 16),
Text('Enter your password to confirm:', style: GoogleFonts.barlow(fontSize: 13, color: textMuted)),
const SizedBox(height: 8),
TextField(
controller: passwordController,
obscureText: true,
style: GoogleFonts.barlow(fontSize: 14, color: textPrimary),
decoration: InputDecoration(
hintText: 'Your password',
hintStyle: GoogleFonts.barlow(fontSize: 13, color: const Color(0xFF3A5070)),
filled: true, fillColor: background, contentPadding: const EdgeInsets.all(12),
enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1C2E45))),
focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: danger)),
),
),
]),
actions: [
TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('CANCEL', style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w900, color: textMuted))),
TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('DELETE FOREVER', style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w900, color: danger))),
],
),
);
if (confirmed != true) return;
if (passwordController.text.isEmpty) {
if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password required to delete account'), backgroundColor: Color(0xFFEF4444)));
return;
}

try {
// Re-authenticate first
final user = FirebaseAuth.instance.currentUser;
if (user == null) return;
final email = user.email ?? '';
final credential = EmailAuthProvider.credential(email: email, password: passwordController.text);
await user.reauthenticateWithCredential(credential);

// Delete all loads
final loads = await FirebaseFirestore.instance.collection('loads').where('userId', isEqualTo: uid).get();
for (final doc in loads.docs) { await doc.reference.delete(); }
// Delete all expenses
final expenses = await FirebaseFirestore.instance.collection('expenses').where('userId', isEqualTo: uid).get();
for (final doc in expenses.docs) { await doc.reference.delete(); }
// Delete user document
await FirebaseFirestore.instance.collection('users').doc(uid).delete();
// Delete Firebase Auth account
await user.delete();
if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
} on FirebaseAuthException catch (e) {
String msg = 'Error deleting account';
if (e.code == 'wrong-password') msg = 'Incorrect password. Please try again.';
if (e.code == 'too-many-requests') msg = 'Too many attempts. Please try again later.';
if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: danger));
} catch (e) {
if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error deleting account. Please contact customerservice@yuploaded.com'), backgroundColor: Color(0xFFEF4444)));
}
}

Future<void> _uploadLicense(String uid) async {
// Show certification dialog first
final confirmed = await showDialog<bool>(
context: context,
builder: (ctx) => AlertDialog(
backgroundColor: surface,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
title: Text('Certify Your License', style: GoogleFonts.barlowCondensed(fontSize: 20, fontWeight: FontWeight.w900, color: textPrimary)),
content: Text('I certify that the driver license I am about to upload belongs to me and is valid. I understand that uploading a license that is not mine may constitute fraud under federal law and violates YUPLOADED Terms of Service.', style: GoogleFonts.barlow(fontSize: 13, color: textMuted, height: 1.6)),
actions: [
TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('NOPE', style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w900, color: textMuted))),
TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('I CERTIFY — YUP', style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w900, color: orange))),
],
),
);
if (confirmed != true) return;
try {
final picker = ImagePicker();
final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
if (picked == null) return;
final ref = FirebaseStorage.instance.ref().child('licenses/' + uid + '/license.jpg');
await ref.putFile(File(picked.path));
final url = await ref.getDownloadURL();
await FirebaseFirestore.instance.collection('users').doc(uid).update({'licenseUrl': url});
if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('License uploaded'), backgroundColor: Color(0xFF4ADE80)));
} catch (e) {}
}

Widget _licenseRow(BuildContext context, String licenseUrl, String uid) {
final hasLicense = licenseUrl.isNotEmpty;
return GestureDetector(
onTap: hasLicense ? null : () => _uploadLicense(uid),
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
decoration: BoxDecoration(border: Border(bottom: BorderSide(color: border, width: 0.5))),
child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
Text('Driver License', style: GoogleFonts.barlow(fontSize: 14, color: textPrimary, fontWeight: FontWeight.w500)),
Row(children: [
Text(hasLicense ? 'On file' : 'Tap to upload', style: GoogleFonts.barlow(fontSize: 13, color: hasLicense ? success : orange)),
const SizedBox(width: 8),
Icon(hasLicense ? Icons.lock : Icons.upload, size: 14, color: hasLicense ? textMuted : orange),
]),
]),
),
);
}

@override
Widget build(BuildContext context) {
final user = FirebaseAuth.instance.currentUser;
return Scaffold(
backgroundColor: background,
body: SafeArea(
child: StreamBuilder<DocumentSnapshot>(
stream: user != null ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots() : null,
builder: (context, snapshot) {
final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
final firstName = userData['firstName'] ?? '';
final lastName = userData['lastName'] ?? '';
final email = userData['email'] ?? user?.email ?? '';
final mcDot = userData['mcDot'] ?? '';
final equipmentType = userData['equipmentType'] ?? '';
final dispatcherEmail = userData['dispatcherEmail'] ?? '';
final plan = userData['plan'] ?? 'FREE';
final planPrice = userData['planPrice'] ?? '0';
final totalLoads = (userData['totalLoads'] ?? 0) as int;
final verifiedLoads = (userData['verifiedLoads'] ?? 0) as int;
final isVerified = verifiedLoads >= 100;
final photoUrl = userData['photoUrl'] ?? '';
final licenseUrl = userData['licenseUrl'] ?? '';
final initials = firstName.isNotEmpty && lastName.isNotEmpty
? firstName[0].toUpperCase() + lastName[0].toUpperCase()
: firstName.isNotEmpty ? firstName[0].toUpperCase() : 'D';

return SingleChildScrollView(
padding: const EdgeInsets.all(24),
child: Column(children: [

// HEADER
Row(children: [
GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 36, height: 36, decoration: BoxDecoration(color: orange, shape: BoxShape.circle), child: const Center(child: Icon(Icons.chevron_left, color: Colors.white, size: 22)))),
const SizedBox(width: 16),
GestureDetector(
onTap: user != null ? () => _uploadProfilePhoto(user.uid) : null,
child: Stack(children: [
Container(
width: 60, height: 60,
decoration: BoxDecoration(color: isVerified ? success : orange, shape: BoxShape.circle, border: Border.all(color: isVerified ? success : orange.withValues(alpha: 0.3), width: 3)),
child: _isUploadingPhoto
? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
: photoUrl.isNotEmpty
? ClipOval(child: Image.network(photoUrl, width: 60, height: 60, fit: BoxFit.cover))
: Center(child: isVerified ? const Icon(Icons.shield, color: Colors.white, size: 24) : Text(initials, style: GoogleFonts.barlowCondensed(fontSize: 22, fontWeight: FontWeight.w900, color: background))),
),
Positioned(bottom: 0, right: 0, child: Container(width: 22, height: 22, decoration: BoxDecoration(color: surface, shape: BoxShape.circle, border: Border.all(color: background, width: 2)), child: const Center(child: Icon(Icons.camera_alt, size: 11, color: Colors.white)))),
]),
),
const SizedBox(width: 14),
Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
Text(firstName.isNotEmpty ? firstName + ' ' + lastName : 'Driver', style: GoogleFonts.barlowCondensed(fontSize: 22, fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: -0.5)),
Text(email, style: GoogleFonts.barlow(fontSize: 12, color: textMuted)),
])),
]),

const SizedBox(height: 16),

// VERIFIED STATUS
Container(
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: isVerified ? success.withValues(alpha: 0.5) : orange.withValues(alpha: 0.3))),
child: Column(children: [
Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
Row(children: [
Icon(Icons.shield, color: isVerified ? success : textMuted, size: 16),
const SizedBox(width: 8),
Text(isVerified ? 'YUPLOADED VERIFIED' : 'ROAD TO VERIFIED', style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: isVerified ? success : textMuted)),
]),
Text(isVerified ? 'Earned. Not bought.' : verifiedLoads.toString() + ' of 100', style: GoogleFonts.barlowCondensed(fontSize: 13, fontWeight: FontWeight.w800, color: isVerified ? success : orange)),
]),
const SizedBox(height: 8),
ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: isVerified ? 1.0 : (verifiedLoads / 100).clamp(0.0, 1.0), backgroundColor: background, valueColor: AlwaysStoppedAnimation<Color>(isVerified ? success : orange), minHeight: 6)),
const SizedBox(height: 4),
Text(totalLoads.toString() + ' total loads uploaded', style: GoogleFonts.barlow(fontSize: 11, color: textMuted)),
]),
),

const SizedBox(height: 16),

// IDENTITY - LOCKED
_buildSectionLabel('IDENTITY — LOCKED'),
Container(
decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
child: Column(children: [
_lockedRow('Full Name', firstName + ' ' + lastName),
_lockedRow('MC Number', mcDot.isNotEmpty ? 'MC-' + mcDot : 'Not set'),
_lockedRow('Equipment Type', equipmentType.isNotEmpty ? equipmentType : 'Not set'),
_licenseRow(context, licenseUrl, user?.uid ?? ''),
if (userData['isFleetOwner'] == true)
_lockedRow('Fleet Code', userData['fleetCode'] ?? '', valueColor: orange),
if (userData['isFleetDriver'] == true)
_lockedRow('Fleet', 'Driver account', valueColor: textMuted),
]),
),
Padding(
padding: const EdgeInsets.only(top: 6, bottom: 4),
child: Row(children: [
const Icon(Icons.lock, size: 12, color: Color(0xFF5A7A9A)),
const SizedBox(width: 6),
Expanded(child: Text('Identity fields are locked to prevent account fraud. Email customerservice@yuploaded.com to request changes.', style: GoogleFonts.barlow(fontSize: 10, color: textMuted))),
]),
),

const SizedBox(height: 16),

// BUSINESS SETTINGS - EDITABLE
_buildSectionLabel('BUSINESS SETTINGS'),
Container(
decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
child: Column(children: [
_editableRow('Dispatcher Email', dispatcherEmail.isNotEmpty ? dispatcherEmail : 'Tap to add', valueColor: dispatcherEmail.isEmpty ? textMuted : orange, onTap: user != null ? () => _editDispatcherEmail(context, dispatcherEmail, user.uid) : null),
]),
),

const SizedBox(height: 16),

// BILLING
_buildSectionLabel('BILLING'),
Container(
decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
child: Column(children: [
_lockedRow('Plan', plan + ' - USD ' + planPrice + '/mo', valueColor: orange),
_editableRow('Upgrade Plan', '', isAction: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentPage()))),
]),
),

const SizedBox(height: 16),

// SIGN OUT
Container(
decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
child: Column(children: [
_editableRow('Sign Out', '', valueColor: danger, isAction: true, onTap: () async {
await FirebaseAuth.instance.signOut();
if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
}),
_editableRow('Delete Account', '', valueColor: danger, isAction: true, onTap: user != null ? () => _deleteAccount(context, user.uid) : null),
]),
),

const SizedBox(height: 24),
]),
);
},
),
),
);
}

Widget _buildSectionLabel(String label) {
return Padding(padding: const EdgeInsets.only(bottom: 8), child: Align(alignment: Alignment.centerLeft, child: Text(label, style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: textMuted))));
}

Widget _lockedRow(String label, String value, {Color? valueColor}) {
return Container(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
decoration: BoxDecoration(border: Border(bottom: BorderSide(color: border, width: 0.5))),
child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
Text(label, style: GoogleFonts.barlow(fontSize: 14, color: textPrimary, fontWeight: FontWeight.w500)),
Row(children: [
Flexible(child: Text(value, style: GoogleFonts.barlow(fontSize: 13, color: valueColor ?? textMuted), textAlign: TextAlign.right)),
const SizedBox(width: 8),
const Icon(Icons.lock, size: 12, color: Color(0xFF3A5070)),
]),
]),
);
}

Widget _editableRow(String label, String value, {Color? valueColor, bool isAction = false, VoidCallback? onTap}) {
return GestureDetector(
onTap: onTap,
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
decoration: BoxDecoration(border: Border(bottom: BorderSide(color: border, width: 0.5))),
child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
Text(label, style: GoogleFonts.barlow(fontSize: 14, color: isAction && valueColor != null ? valueColor : textPrimary, fontWeight: FontWeight.w500)),
if (!isAction) Flexible(child: Text(value, style: GoogleFonts.barlow(fontSize: 13, color: valueColor ?? textMuted), textAlign: TextAlign.right)),
if (isAction) const Icon(Icons.chevron_right, color: Color(0xFF5A7A9A), size: 20),
]),
),
);
}
}

