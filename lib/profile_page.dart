import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: background,
body: SafeArea(
child: SingleChildScrollView(
padding: const EdgeInsets.all(24),
child: Column(
children: [

// AVATAR + NAME
Row(
children: [
Stack(
children: [
Container(
width: 64, height: 64,
decoration: BoxDecoration(
color: orange,
shape: BoxShape.circle,
border: Border.all(color: orange.withValues(alpha: 0.3), width: 3),
),
child: Center(
child: Text('MT', style: GoogleFonts.barlowCondensed(fontSize: 24, fontWeight: FontWeight.w900, color: background)),
),
),
Positioned(
bottom: 0, right: 0,
child: Container(
width: 22, height: 22,
decoration: BoxDecoration(color: surface, shape: BoxShape.circle, border: Border.all(color: background, width: 2)),
child: const Center(
child: Icon(Icons.camera_alt, size: 12, color: Colors.white),
),
),
),
],
),
const SizedBox(width: 14),
Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('Mike Torres', style: GoogleFonts.barlowCondensed(fontSize: 24, fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: -0.5)),
Text('mike@torres.com', style: GoogleFonts.barlow(fontSize: 12, color: textMuted)),
],
),
],
),

const SizedBox(height: 16),

// ENGAGEMENT STATS
Row(
children: [
Expanded(child: _buildStatCard(Icons.emoji_events, 'Highway Pro', 'Current Rank', orange)),
const SizedBox(width: 8),
Expanded(child: _buildStatCard(Icons.local_shipping, '87 Loads', 'Uploaded', textPrimary)),
const SizedBox(width: 8),
Expanded(child: _buildStatCard(Icons.speed, '9,847', 'Miles / Month', textPrimary)),
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
Text('Highway Pro → Veteran Hauler', style: GoogleFonts.barlowCondensed(fontSize: 13, fontWeight: FontWeight.w800, color: textPrimary)),
Text('87/100', style: GoogleFonts.barlowCondensed(fontSize: 13, fontWeight: FontWeight.w800, color: orange)),
],
),
const SizedBox(height: 8),
ClipRRect(
borderRadius: BorderRadius.circular(4),
child: LinearProgressIndicator(
value: 0.87,
backgroundColor: background,
valueColor: const AlwaysStoppedAnimation<Color>(orange),
minHeight: 6,
),
),
const SizedBox(height: 6),
Text('13 more loads to reach Veteran Hauler', style: GoogleFonts.barlow(fontSize: 11, color: textMuted)),
],
),
),

const SizedBox(height: 16),

// BUSINESS INFO
_buildSectionLabel('BUSINESS INFO'),
_buildInfoCard([
_buildInfoRow('MC Number', 'MC-847291'),
_buildInfoRow('DOT Number', '3847201'),
_buildInfoRow('Company Name', 'Torres Trucking'),
_buildInfoRow('Dispatcher Email', 'dispatch@jt.com', valueColor: orange),
]),

const SizedBox(height: 16),

// BILLING
_buildSectionLabel('BILLING'),
_buildInfoCard([
_buildInfoRow('Plan', 'Founding · \$19/mo', valueColor: orange),
_buildInfoRow('Next Billing', 'Jul 28, 2026'),
_buildInfoRow('Card on File', 'Visa .... 4291'),
_buildInfoRow('Update Card', '', isAction: true),
]),

const SizedBox(height: 16),

// CANCEL
Container(
decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
child: _buildInfoRow('Cancel Subscription', '', valueColor: danger, isAction: true),
),

const SizedBox(height: 12),

Center(
child: Text('Sign Out', style: GoogleFonts.barlow(fontSize: 14, color: textMuted, fontWeight: FontWeight.w500)),
),

const SizedBox(height: 24),
],
),
),
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
child: Text(label, style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: textMuted)),
);
}

Widget _buildInfoCard(List<Widget> rows) {
return Container(
decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
child: Column(children: rows),
);
}

Widget _buildInfoRow(String label, String value, {Color? valueColor, bool isAction = false}) {
return Container(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
decoration: BoxDecoration(border: Border(bottom: BorderSide(color: border, width: 0.5))),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(label, style: GoogleFonts.barlow(fontSize: 14, color: isAction && valueColor != null ? valueColor : textPrimary, fontWeight: FontWeight.w500)),
if (!isAction) Text(value, style: GoogleFonts.barlow(fontSize: 14, color: valueColor ?? textMuted)),
if (isAction) const Icon(Icons.chevron_right, color: Color(0xFF5A7A9A), size: 20),
],
),
);
}
}