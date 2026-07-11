import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'quick_details_page.dart';

class NewLoadPage extends StatefulWidget {
const NewLoadPage({super.key});
@override
State<NewLoadPage> createState() => _NewLoadPageState();
}

class _NewLoadPageState extends State<NewLoadPage> {
int _rateTab = 0;
bool? _rateStatus;
bool? _bolStatus;
bool? _freightStatus;
bool? _podStatus;
bool _isUploading = false;
final _rateController = TextEditingController();
List<String> _freightUrls = [];

static const Color background = Color(0xFF0B1628);
static const Color surface = Color(0xFF122035);
static const Color border = Color(0xFF1C2E45);
static const Color orange = Color(0xFFF5921E);
static const Color textPrimary = Color(0xFFFFFFFF);
static const Color textMuted = Color(0xFF5A7A9A);
static const Color success = Color(0xFF4ADE80);

bool get _allDone => _rateStatus != null && _bolStatus != null && _freightStatus != null && _podStatus != null;
int get _completedCount => [_rateStatus, _bolStatus, _freightStatus, _podStatus].where((s) => s != null).length;

Future<String?> _uploadSinglePhoto(String folder) async {
try {
final picker = ImagePicker();
final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
if (picked == null) return null;
setState(() => _isUploading = true);
final user = FirebaseAuth.instance.currentUser;
final uid = user?.uid ?? 'unknown';
final fileName = uid + '_' + folder + '_' + DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
final ref = FirebaseStorage.instance.ref().child('loads/' + uid + '/' + folder + '/' + fileName);
await ref.putFile(File(picked.path));
final url = await ref.getDownloadURL();
setState(() => _isUploading = false);
return url;
} catch (e) {
setState(() => _isUploading = false);
return null;
}
}

Future<void> _uploadMultiplePhotos() async {
try {
final picker = ImagePicker();
final picked = await picker.pickMultiImage(imageQuality: 70);
if (picked.isEmpty) return;
setState(() => _isUploading = true);
final user = FirebaseAuth.instance.currentUser;
final uid = user?.uid ?? 'unknown';
for (final img in picked) {
final fileName = uid + '_freight_' + DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
final ref = FirebaseStorage.instance.ref().child('loads/' + uid + '/freight/' + fileName);
await ref.putFile(File(img.path));
final url = await ref.getDownloadURL();
_freightUrls.add(url);
}
setState(() { _isUploading = false; _freightStatus = true; });
} catch (e) {
setState(() => _isUploading = false);
}
}

Widget _buildProgressSegment(bool? status) {
Color color = status == true ? orange : status == false ? textMuted : surface;
return Expanded(child: Container(height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))));
}

Widget _buildSlotStatus(bool? status, String yupped, String noped) {
if (status == true) return Text(yupped, style: GoogleFonts.barlow(fontSize: 11, color: success));
if (status == false) return Text(noped, style: GoogleFonts.barlow(fontSize: 11, color: textMuted));
return const SizedBox.shrink();
}

Widget _buildBadge(bool? status) {
if (status == true) return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Text('YUP', style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w800, color: success)));
if (status == false) return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: textMuted.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Text('SKIPPED', style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w800, color: textMuted)));
return const SizedBox.shrink();
}

Widget _yupNope(VoidCallback onYup, VoidCallback onNope) {
return Row(children: [
Expanded(child: GestureDetector(onTap: onYup, child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(10)), child: Center(child: Text('YUP', style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w900, color: background, letterSpacing: 2)))))),
const SizedBox(width: 8),
Expanded(child: GestureDetector(onTap: onNope, child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(border: Border.all(color: border, width: 2), borderRadius: BorderRadius.circular(10)), child: Center(child: Text('NOPE', style: GoogleFonts.barlowCondensed(fontSize: 15, fontWeight: FontWeight.w900, color: textMuted, letterSpacing: 1)))))),
]);
}

Widget _buildDocSlot({required IconData icon, required String title, required bool? status, required VoidCallback onYup, required VoidCallback onNope}) {
return Container(
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: status == true ? success : status == false ? textMuted : border, width: 1.5)),
child: Column(children: [
Row(children: [
Icon(icon, color: orange, size: 20),
const SizedBox(width: 12),
Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
Text(title, style: GoogleFonts.barlowCondensed(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary)),
_buildSlotStatus(status, 'Yupped', 'Skipped'),
if (status == null) Text('Select from your camera roll', style: GoogleFonts.barlow(fontSize: 11, color: textMuted)),
])),
_buildBadge(status),
]),
if (status == null) ...[const SizedBox(height: 10), _yupNope(onYup, onNope)],
]),
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: background,
body: SafeArea(
child: Column(children: [
Padding(
padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
child: Row(children: [
GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 36, height: 36, decoration: BoxDecoration(color: orange, shape: BoxShape.circle), child: const Center(child: Icon(Icons.chevron_left, color: Colors.white, size: 22)))),
const SizedBox(width: 12),
Text('Upload Your Docs', style: GoogleFonts.barlowCondensed(fontSize: 24, fontWeight: FontWeight.w900, color: textPrimary)),
const Spacer(),
Text(_completedCount.toString() + '/4', style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w800, color: textMuted)),
]),
),
Padding(
padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
child: Row(children: [
_buildProgressSegment(_rateStatus), const SizedBox(width: 6),
_buildProgressSegment(_bolStatus), const SizedBox(width: 6),
_buildProgressSegment(_freightStatus), const SizedBox(width: 6),
_buildProgressSegment(_podStatus), const SizedBox(width: 6),
_buildProgressSegment(_allDone ? true : null),
]),
),
if (_isUploading) Padding(
padding: const EdgeInsets.symmetric(vertical: 8),
child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Color(0xFFF5921E), strokeWidth: 2)),
const SizedBox(width: 8),
Text('Uploading...', style: GoogleFonts.barlow(fontSize: 12, color: textMuted)),
]),
),
Padding(
padding: const EdgeInsets.fromLTRB(24, 8, 24, 10),
child: Text('Take photos first then upload here. Tap NOPE to skip.', style: GoogleFonts.barlow(fontSize: 11, color: textMuted), textAlign: TextAlign.center),
),
Expanded(
child: SingleChildScrollView(
padding: const EdgeInsets.symmetric(horizontal: 24),
child: Column(children: [
Container(
decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: _rateStatus == true ? success : _rateStatus == false ? textMuted : orange, width: 1.5)),
child: Column(children: [
Padding(
padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
child: Row(children: [
const Icon(Icons.description, color: Color(0xFFF5921E), size: 20),
const SizedBox(width: 12),
Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
Text('RATE CONFIRMATION', style: GoogleFonts.barlowCondensed(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary)),
_buildSlotStatus(_rateStatus, 'Yupped', 'Skipped'),
if (_rateStatus == null) Text('Type it or upload it', style: GoogleFonts.barlow(fontSize: 11, color: orange)),
])),
_buildBadge(_rateStatus),
]),
),
if (_rateStatus == null) ...[
Row(children: [
Expanded(child: GestureDetector(onTap: () => setState(() => _rateTab = 0), child: Container(padding: const EdgeInsets.symmetric(vertical: 10), color: _rateTab == 0 ? orange : const Color(0xFF0D1E30), child: Center(child: Text('TYPE AMOUNT', style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w800, color: _rateTab == 0 ? background : textPrimary)))))),
Expanded(child: GestureDetector(onTap: () => setState(() => _rateTab = 1), child: Container(padding: const EdgeInsets.symmetric(vertical: 10), color: _rateTab == 1 ? orange : const Color(0xFF0D1E30), child: Center(child: Text('UPLOAD PHOTO', style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w800, color: _rateTab == 1 ? background : textPrimary)))))),
]),
Padding(
padding: const EdgeInsets.all(12),
child: _rateTab == 0
? Column(children: [
TextField(controller: _rateController, keyboardType: TextInputType.number, style: GoogleFonts.barlowCondensed(fontSize: 28, fontWeight: FontWeight.w900, color: orange), decoration: InputDecoration(hintText: '0.00', hintStyle: GoogleFonts.barlowCondensed(fontSize: 28, color: const Color(0xFF2A4060)), filled: true, fillColor: background, contentPadding: const EdgeInsets.all(14), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFF5921E), width: 1.5)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFF5921E), width: 1.5)))),
const SizedBox(height: 10),
_yupNope(() => setState(() => _rateStatus = true), () => setState(() => _rateStatus = false)),
])
: _yupNope(
() async { final url = await _uploadSinglePhoto('ratcon'); setState(() { _rateStatus = true; }); },
() => setState(() => _rateStatus = false),
),
),
],
]),
),
const SizedBox(height: 10),
_buildDocSlot(icon: Icons.article, title: 'BILL OF LADING', status: _bolStatus, onYup: () async { await _uploadSinglePhoto('bol'); setState(() => _bolStatus = true); }, onNope: () => setState(() => _bolStatus = false)),
const SizedBox(height: 10),
Container(
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: _freightStatus == true ? success : _freightStatus == false ? textMuted : border, width: 1.5)),
child: Column(children: [
Row(children: [
const Icon(Icons.photo_library, color: Color(0xFFF5921E), size: 20),
const SizedBox(width: 12),
Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
Text('FREIGHT PHOTOS', style: GoogleFonts.barlowCondensed(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary)),
_buildSlotStatus(_freightStatus, _freightUrls.length.toString() + ' photo(s) uploaded', 'Skipped'),
if (_freightStatus == null) Text('Select multiple from camera roll', style: GoogleFonts.barlow(fontSize: 11, color: textMuted)),
])),
_buildBadge(_freightStatus),
]),
if (_freightStatus == null) ...[const SizedBox(height: 10), _yupNope(_uploadMultiplePhotos, () => setState(() => _freightStatus = false))],
if (_freightStatus == true) ...[
const SizedBox(height: 10),
GestureDetector(onTap: _uploadMultiplePhotos, child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(border: Border.all(color: orange, width: 1.5), borderRadius: BorderRadius.circular(10)), child: Center(child: Text('+ ADD MORE PHOTOS', style: GoogleFonts.barlowCondensed(fontSize: 13, fontWeight: FontWeight.w800, color: orange, letterSpacing: 1))))),
],
]),
),
const SizedBox(height: 10),
_buildDocSlot(icon: Icons.check_circle, title: 'PROOF OF DELIVERY', status: _podStatus, onYup: () async { await _uploadSinglePhoto('pod'); setState(() => _podStatus = true); }, onNope: () => setState(() => _podStatus = false)),
const SizedBox(height: 16),
if (_allDone) SizedBox(
width: double.infinity, height: 56,
child: ElevatedButton(
onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickDetailsPage())),
style: ElevatedButton.styleFrom(backgroundColor: orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
child: Text('NEXT - QUICK DETAILS', style: GoogleFonts.barlowCondensed(fontSize: 18, fontWeight: FontWeight.w900, color: background, letterSpacing: 2)),
),
),
const SizedBox(height: 24),
]),
),
),
]),
),
);
}
}