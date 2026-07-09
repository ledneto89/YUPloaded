import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'payment_page.dart';

class ProfilePage extends StatelessWidget {
const ProfilePage({super.key});

static const Color background = Color(0xFF0B1628);
static const Color surface = Color(0xFF122035);
static const Color border = Color(0xFF1C2E45);
static const Color orange = Color(0xFFF5921E);
static const Color textPrimary = Color(0xFFFFFFFF);
static const Color textMuted = Color(0xFF5A7A9A);
static const Color success = Color(0xFF4ADE80);
static const Color danger = Color(0xFFEF4444);

String _getRank(int totalLoads) {
if (totalLoads >= 500) return 'YUPLOADED Elite';
if (totalLoads >= 250) return 'Road Legend';
if (totalLoads >= 100) return 'Veteran Hauler';
if (totalLoads >= 50) return 'Highway Pro';
if (totalLoads >= 10) return 'Road Warrior';
return 'Rookie';
}

@override
Widget build(BuildContext context) {
final user = FirebaseAuth.instance.currentUser;

return Scaffold(
backgroundColor: background,
body: SafeArea(
child: StreamBuilder<DocumentSnapshot>(
stream: user != null
? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
: null,
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
final rank = _getRank(totalLoads);
final initials = firstName.isNotEmpty && lastName.isNotEmpty
? firstName[0].toUpperCase() + lastName[0].toUpperCase()
: firstName.isNotEmpty ? firstName[0].toUpperCase() : 'D';

return SingleChildScrollView(
padding: const EdgeInsets.all(24),
child: Column(
children: [

// AVATAR + NAME
Row(
children: [
GestureDetector(
onTap: () => Navigator.pop(context),
child: Container(
width: 34, height: 34,
decoration: BoxDecoration(color: surface, shape: BoxShape.circle),
child: const Center(child: Icon(Icons.chevron_left, color: Colors.white, size: 20)),
),
),
const SizedBox(width: 16),
Stack(
children: [
Container(
width: 56, height: 56,
decoration: BoxDecoration(color: orange, shape: BoxShape.circle, border: Border.all(color: orange.withValues(alpha: 0.3), width: 3)),
child: Center(child: Text(initials, style: GoogleFonts.barlowCondensed(fontSize: 22, fontWeight: FontWeight.w900, color: background))),
),
Positioned(
bottom: 0, right: 0,
child: Container(
width: 20, height: 20,
decoration: BoxDecoration(color: surface, shape: BoxShape.circle, border: Border.all(color: background, width: 2)),
child: const Center(child: Icon(Icons.camera_alt, size: 10, color: Colors.white)),
),
),
],
),
const SizedBox(width: 14),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
firstName.isNotEmpty ? firstName + ' ' + lastName : 'Driver',
style: GoogleFonts.barlowCondensed(fontSize: 22, fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: -0.5),
),
Text(email, style: GoogleFonts.barlow(fontSize: 12, color: textMuted)),
],
),
),
],
),

const SizedBox(height: 16),

// ENGAGEMENT STATS
Row(
children: [
Expanded(child: _buildStatCard(Icons.emoji_events, rank, 'Current Rank', orange)),
const SizedBox(width: 8),
Expanded(child: _buildStatCard(Icons.local_shipping, totalLoads.toString() + ' Loads', 'Uploaded', textPrimary)),
],
),

const SizedBox(height: 12),

// RANK PROGRESS BAR
Container(
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(rank, style: GoogleFonts.barlowCondensed(fontSize: 13, fontWeight: FontWeight.w800, color: textPrimary)),
Text(totalLoads.toString() + ' loads', style: GoogleFonts.barlowCondensed(fontSize: 13, fontWeight: FontWeight.w800, color: orange)),
],
),
const SizedBox(height: 8),
ClipRRect(
borderRadius: BorderRadius.circular(4),
child: LinearProgressIndicator(
value: totalLoads >= 500 ? 1.0 : (totalLoads % 100) / 100,
backgroundColor: background,
valueColor: const AlwaysStoppedAnimation<Color>(orange),
minHeight: 6,
),
),
],
),
),

const SizedBox(height: 16),

// BUSINESS INFO
_buildSectionLabel('BUSINESS INFO'),
_buildInfoCard([
_buildInfoRow('MC / DOT Number', mcDot.isNotEmpty ? mcDot : 'Not set', onTap: () => _editField(context, 'mcDot', 'MC / DOT Number', mcDot, user?.uid)),
_buildInfoRow('Equipment Type', equipmentType.isNotEmpty ? equipmentType : 'Not set', onTap: () {}),
_buildInfoRow('Dispatcher Email', dispatcherEmail.isNotEmpty ? dispatcherEmail : 'Not set', valueColor: dispatcherEmail.isNotEmpty ? orange : textMuted, onTap: () => _editField(context, 'dispatcherEmail', 'Dispatcher Email', dispatcherEmail, user?.uid)),
]),

const SizedBox(height: 16),

// BILLING
_buildSectionLabel('BILLING'),
_buildInfoCard([
_buildInfoRow('Plan', plan + ' - USD ' + planPrice + '/mo', valueColor: orange),
_buildInfoRow('Upgrade Plan', '', isAction: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentPage()))),
]),

const SizedBox(height: 16),

// SIGN OUT
Container(
decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
child: _buildInfoRow(
'Sign Out',
'',
valueColor: danger,
isAction: true,
onTap: () async {
await FirebaseAuth.instance.signOut();
if (context.mounted) {
Navigator.pushAndRemoveUntil(
context,
MaterialPageRoute(builder: (_) => const LoginPage()),
(route) => false,
);
}
},
),
),

const SizedBox(height: 24),
],
),
);
},
),
),
);
}

Future<void> _editField(BuildContext context, String field, String label, String currentValue, String? uid) async {
if (uid == null) return;
final controller = TextEditingController(text: currentValue);
await showDialog(
context: context,
builder: (ctx) => AlertDialog(
backgroundColor: surface,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
title: Text('Update ' + label, style: GoogleFonts.barlowCondensed(fontSize: 20, fontWeight: FontWeight.w900, color: textPrimary)),
content: TextField(
controller: controller,
style: GoogleFonts.barlow(fontSize: 14, color: textPrimary),
decoration: InputDecoration(
filled: true,
fillColor: background,
enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1C2E45))),
focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFF5921E))),
),
),
actions: [
TextButton(onPressed: () => Navigator.pop(ctx), child: Text('NOPE', style: GoogleFonts.barlowCondensed(fontSize: 15, fontWeight: FontWeight.w900, color: textMuted))),
TextButton(
onPressed: () async {
await FirebaseFirestore.instance.collection('users').doc(uid).update({field: controller.text.trim()});
if (ctx.mounted) Navigator.pop(ctx);
},
child: Text('YUP', style: GoogleFonts.barlowCondensed(fontSize: 15, fontWeight: FontWeight.w900, color: orange)),
),
],
),
);
}

Widget _buildStatCard(IconData icon, String value, String label, Color valueColor) {
return Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
child: Column(
children: [
Icon(icon, color: orange, size: 22),
const SizedBox(height: 4),
Text(value, style: GoogleFonts.barlowCondensed(fontSize: 13, fontWeight: FontWeight.w900, color: valueColor, letterSpacing: -0.5), textAlign: TextAlign.center),
const SizedBox(height: 2),
Text(label, style: GoogleFonts.barlow(fontSize: 10, color: textMuted), textAlign: TextAlign.center),
],
),
);
}

Widget _buildSectionLabel(String label) {
return Padding(
padding: const EdgeInsets.only(bottom: 8),
child: Align(alignment: Alignment.centerLeft, child: Text(label, style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: textMuted))),
);
}

Widget _buildInfoCard(List<Widget> rows) {
return Container(
decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
child: Column(children: rows),
);
}

Widget _buildInfoRow(String label, String value, {Color? valueColor, bool isAction = false, VoidCallback? onTap}) {
return GestureDetector(
onTap: onTap,
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
decoration: BoxDecoration(border: Border(bottom: BorderSide(color: border, width: 0.5))),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(label, style: GoogleFonts.barlow(fontSize: 14, color: isAction && valueColor != null ? valueColor : textPrimary, fontWeight: FontWeight.w500)),
if (!isAction) Flexible(child: Text(value, style: GoogleFonts.barlow(fontSize: 13, color: valueColor ?? textMuted), textAlign: TextAlign.right)),
if (isAction) const Icon(Icons.chevron_right, color: Color(0xFF5A7A9A), size: 20),
],
),
),
);
}
}
