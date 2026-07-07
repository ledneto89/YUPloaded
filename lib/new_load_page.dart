import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'quick_details_page.dart';

class NewLoadPage extends StatefulWidget {
const NewLoadPage({super.key});

@override
State<NewLoadPage> createState() => _NewLoadPageState();
}

class _NewLoadPageState extends State<NewLoadPage> {
int _rateTab = 0;
bool _rateDone = false;
bool _bolDone = false;
bool _freightDone = false;
bool _podDone = false;
bool _isUploading = false;
final _rateController = TextEditingController();

String? _rateConUrl;
String? _bolUrl;
List<String> _freightUrls = [];
String? _podUrl;

static const Color background = Color(0xFF0B1628);
static const Color surface = Color(0xFF122035);
static const Color border = Color(0xFF1C2E45);
static const Color orange = Color(0xFFF5921E);
static const Color textPrimary = Color(0xFFFFFFFF);
static const Color textMuted = Color(0xFF5A7A9A);
static const Color success = Color(0xFF4ADE80);

bool get _allDone => _rateDone && _bolDone && _freightDone && _podDone;

Future<String?> _uploadPhoto(String folder) async {
try {
final picker = ImagePicker();
final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
if (picked == null) return null;

setState(() => _isUploading = true);

final file = File(picked.path);
final fileName = folder + '_' + DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
final ref = FirebaseStorage.instance.ref().child('loads/' + folder + '/' + fileName);
await ref.putFile(file);
final url = await ref.getDownloadURL();

setState(() => _isUploading = false);
return url;
} catch (e) {
setState(() => _isUploading = false);
return null;
}
}

Future<void> _pickRateCon() async {
final url = await _uploadPhoto('ratcon');
if (url != null) {
setState(() {
_rateConUrl = url;
_rateDone = true;
});
}
}

Future<void> _pickBol() async {
final url = await _uploadPhoto('bol');
if (url != null) {
setState(() {
_bolUrl = url;
_bolDone = true;
});
}
}

Future<void> _pickFreight() async {
final url = await _uploadPhoto('freight');
if (url != null) {
setState(() {
_freightUrls.add(url);
_freightDone = true;
});
}
}

Future<void> _pickPod() async {
final url = await _uploadPhoto('pod');
if (url != null) {
setState(() {
_podUrl = url;
_podDone = true;
});
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: background,
body: SafeArea(
child: Column(
children: [
Padding(
padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
child: Row(
children: [
GestureDetector(
onTap: () => Navigator.pop(context),
child: Container(width: 34, height: 34, decoration: BoxDecoration(color: surface, shape: BoxShape.circle), child: const Center(child: Text('back', style: TextStyle(color: Colors.white, fontSize: 11)))),
),
const SizedBox(width: 12),
Text('Upload Your Docs', style: GoogleFonts.barlowCondensed(fontSize: 24, fontWeight: FontWeight.w900, color: textPrimary)),
],
),
),
Padding(
padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
child: Row(
children: [
_buildProgress(_rateDone),
const SizedBox(width: 6),
_buildProgress(_bolDone),
const SizedBox(width: 6),
_buildProgress(_freightDone),
const SizedBox(width: 6),
_buildProgress(_podDone),
const SizedBox(width: 6),
_buildProgress(false),
],
),
),
if (_isUploading)
Padding(
padding: const EdgeInsets.symmetric(vertical: 8),
child: Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Color(0xFFF5921E), strokeWidth: 2)),
const SizedBox(width: 8),
Text('Uploading...', style: GoogleFonts.barlow(fontSize: 12, color: textMuted)),
],
),
),
Padding(
padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
child: Text('Take your photos first then upload everything here', style: GoogleFonts.barlow(fontSize: 11, color: textMuted), textAlign: TextAlign.center),
),
Expanded(
child: SingleChildScrollView(
padding: const EdgeInsets.symmetric(horizontal: 24),
child: Column(
children: [
Container(
decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: _rateDone ? success : orange, width: 1.5)),
child: Column(
children: [
Padding(
padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
child: Row(
children: [
const Icon(Icons.description, color: Color(0xFFF5921E), size: 20),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('RATE CONFIRMATION', style: GoogleFonts.barlowCondensed(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary)),
Text(_rateDone ? 'Yupped' : 'Type it or upload it', style: GoogleFonts.barlow(fontSize: 11, color: _rateDone ? success : orange)),
],
),
),
if (_rateDone) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Text('YUP', style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w800, color: success))),
],
),
),
if (!_rateDone) ...[
Row(
children: [
Expanded(child: GestureDetector(onTap: () => setState(() => _rateTab = 0), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), color: _rateTab == 0 ? orange : const Color(0xFF0D1E30), child: Column(children: [const Icon(Icons.edit, size: 18, color: Colors.white), const SizedBox(height: 4), Text('TYPE AMOUNT', style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w800, color: _rateTab == 0 ? background : textPrimary))])))),
Expanded(child: GestureDetector(onTap: () => setState(() => _rateTab = 1), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), color: _rateTab == 1 ? orange : const Color(0xFF0D1E30), child: Column(children: [const Icon(Icons.photo_library, size: 18, color: Colors.white), const SizedBox(height: 4), Text('UPLOAD PHOTO', style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w800, color: _rateTab == 1 ? background : textPrimary))])))),
],
),
Padding(
padding: const EdgeInsets.all(12),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
if (_rateTab == 0) ...[
Text('AGREED RATE', style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: textMuted)),
const SizedBox(height: 6),
TextField(
controller: _rateController,
keyboardType: TextInputType.number,
style: GoogleFonts.barlowCondensed(fontSize: 28, fontWeight: FontWeight.w900, color: orange),
decoration: InputDecoration(hintText: '0.00', hintStyle: GoogleFonts.barlowCondensed(fontSize: 28, color: const Color(0xFF2A4060)), filled: true, fillColor: background, contentPadding: const EdgeInsets.all(14), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFF5921E), width: 1.5)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFF5921E), width: 1.5))),
),
const SizedBox(height: 12),
GestureDetector(
onTap: () => setState(() => _rateDone = true),
child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(10)), child: Center(child: Text('YUP - CONFIRM RATE', style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w900, color: background, letterSpacing: 2)))),
),
] else ...[
GestureDetector(
onTap: _pickRateCon,
child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(10)), child: Center(child: Text('YUP - SELECT FROM PHOTOS', style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w900, color: background, letterSpacing: 1)))),
),
const SizedBox(height: 8),
GestureDetector(
onTap: () => setState(() => _rateDone = true),
child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(border: Border.all(color: border, width: 2), borderRadius: BorderRadius.circular(10)), child: Center(child: Text('NOPE', style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w900, color: textMuted, letterSpacing: 2)))),
),
],
],
),
),
],
],
),
),
const SizedBox(height: 10),
_buildUploadSlot(Icons.article, 'BILL OF LADING', 'Select from your camera roll', _bolDone, _pickBol, () => setState(() => _bolDone = true)),
const SizedBox(height: 10),
_buildUploadSlot(Icons.image, 'FREIGHT PHOTOS', 'Select from your camera roll', _freightDone, _pickFreight, () => setState(() => _freightDone = true)),
const SizedBox(height: 10),
_buildUploadSlot(Icons.check_circle, 'PROOF OF DELIVERY', 'Select from your camera roll', _podDone, _pickPod, () => setState(() => _podDone = true)),
const SizedBox(height: 16),
if (_allDone)
SizedBox(
width: double.infinity,
height: 56,
child: ElevatedButton(
onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickDetailsPage())),
style: ElevatedButton.styleFrom(backgroundColor: orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
child: Text('NEXT - QUICK DETAILS', style: GoogleFonts.barlowCondensed(fontSize: 18, fontWeight: FontWeight.w900, color: background, letterSpacing: 2)),
),
),
const SizedBox(height: 24),
],
),
),
),
],
),
),
);
}

Widget _buildProgress(bool done) {
return Expanded(child: Container(height: 4, decoration: BoxDecoration(color: done ? orange : surface, borderRadius: BorderRadius.circular(2))));
}

Widget _buildUploadSlot(IconData icon, String title, String subtitle, bool done, VoidCallback onYup, VoidCallback onNope) {
return Container(
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: done ? success : border, width: 1.5)),
child: Column(
children: [
Row(
children: [
Icon(icon, color: orange, size: 20),
const SizedBox(width: 12),
Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.barlowCondensed(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary)), Text(done ? 'Yupped' : subtitle, style: GoogleFonts.barlow(fontSize: 11, color: done ? success : textMuted))])),
if (done) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Text('YUP', style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w800, color: success))),
],
),
if (!done) ...[
const SizedBox(height: 10),
Row(
children: [
Expanded(child: GestureDetector(onTap: onYup, child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(10)), child: Center(child: Text('YUP - SELECT PHOTO', style: GoogleFonts.barlowCondensed(fontSize: 14, fontWeight: FontWeight.w900, color: background, letterSpacing: 1)))))),
const SizedBox(width: 8),
Expanded(child: GestureDetector(onTap: onNope, child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(border: Border.all(color: border, width: 2), borderRadius: BorderRadius.circular(10)), child: Center(child: Text('NOPE', style: GoogleFonts.barlowCondensed(fontSize: 15, fontWeight: FontWeight.w900, color: textMuted, letterSpacing: 1)))))),
],
),
],
],
),
);
}
}
