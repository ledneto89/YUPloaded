import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'email_service.dart';

class EditLoadPage extends StatefulWidget {
  final String loadId;
  final Map<String, dynamic> loadData;
  const EditLoadPage({super.key, required this.loadId, required this.loadData});
  @override
  State<EditLoadPage> createState() => _EditLoadPageState();
}

class _EditLoadPageState extends State<EditLoadPage> {
  late TextEditingController _rateController;
  late TextEditingController _mileageController;
  late TextEditingController _expensesController;
  late TextEditingController _notesController;
  late TextEditingController _brokerEmailController;
  String? _pickupState;
  String? _deliveryState;
  String _status = 'invoiced';
  bool _isLoading = false;
  bool _isUploading = false;

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
  static const Color info = Color(0xFF60A5FA);

  final List<String> _states = ['AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA','HI','ID','IL','IN','IA','KS','KY','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ','NM','NY','NC','ND','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VT','VA','WA','WV','WI','WY'];

  @override
  void initState() {
    super.initState();
    _rateController = TextEditingController(text: (widget.loadData['rate'] ?? 0.0).toString());
    _mileageController = TextEditingController(text: (widget.loadData['mileage'] ?? 0).toString());
    _expensesController = TextEditingController(text: (widget.loadData['expenses'] ?? 0.0).toString());
    _notesController = TextEditingController(text: widget.loadData['notes'] ?? '');
    _brokerEmailController = TextEditingController(text: widget.loadData['brokerEmail'] ?? '');
    _pickupState = widget.loadData['pickupState'];
    _deliveryState = widget.loadData['deliveryState'];
    _status = widget.loadData['status'] ?? 'invoiced';
    _rateConUrl = widget.loadData['rateConUrl'];
    _bolUrl = widget.loadData['bolUrl'];
    _freightUrls = List<String>.from(widget.loadData['freightUrls'] ?? []);
    _podUrl = widget.loadData['podUrl'];
  }

  Future<String?> _uploadPhoto(String folder) async {
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

  Future<void> _addFreightPhoto() async {
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
      setState(() => _isUploading = false);
    } catch (e) {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('loads').doc(widget.loadId).update({
        'rate': double.tryParse(_rateController.text.replaceAll(',', '')) ?? 0.0,
        'mileage': int.tryParse(_mileageController.text) ?? 0,
        'expenses': double.tryParse(_expensesController.text.replaceAll(',', '')) ?? 0.0,
        'notes': _notesController.text.trim(),
        'brokerEmail': _brokerEmailController.text.trim(),
        'pickupState': _pickupState ?? '',
        'deliveryState': _deliveryState ?? '',
        'status': _status,
        'rateConUrl': _rateConUrl ?? '',
        'bolUrl': _bolUrl ?? '',
        'freightUrls': _freightUrls,
        'podUrl': _podUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Load updated'), backgroundColor: Color(0xFF4ADE80)));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ' + e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendPacket() async {
    final brokerEmail = _brokerEmailController.text.trim();
    final dispatcherEmail = widget.loadData['dispatcherEmail'] ?? '';
    final loadNumber = widget.loadData['loadNumber'] ?? '';
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};
    final driverName = (userData['firstName'] ?? '') + ' ' + (userData['lastName'] ?? '');
    final mcNumber = userData['mcDot'] ?? '';
    final rate = (widget.loadData['rate'] ?? 0.0).toDouble();

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Packet resent'), backgroundColor: Color(0xFF4ADE80)));
    }
  }

  Widget _buildDocPhoto(String? url, String label, IconData icon, VoidCallback onReplace) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: url != null && url.isNotEmpty ? success : border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Icon(icon, color: url != null && url.isNotEmpty ? success : textMuted, size: 16),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.barlowCondensed(fontSize: 12, fontWeight: FontWeight.w700, color: url != null && url.isNotEmpty ? textPrimary : textMuted)),
          ]),
          GestureDetector(
            onTap: onReplace,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(8)),
              child: Text(url != null && url.isNotEmpty ? 'REPLACE' : 'ADD', style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w900, color: background)),
            ),
          ),
        ]),
        if (url != null && url.isNotEmpty) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(url, height: 80, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 80, color: border, child: const Center(child: Icon(Icons.broken_image, color: Colors.white54)))),
          ),
        ],
      ]),
    );
  }

  Widget _field(String label, TextEditingController ctrl, TextInputType type) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: textMuted)),
      const SizedBox(height: 6),
      TextField(controller: ctrl, keyboardType: type, style: GoogleFonts.barlow(fontSize: 14, color: textPrimary), decoration: InputDecoration(filled: true, fillColor: surface, contentPadding: const EdgeInsets.all(14), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1C2E45), width: 1.5)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF5921E), width: 1.5)))),
    ]);
  }

  Widget _dropdown(String label, String? value, Function(String?) onChange) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: textMuted)),
      const SizedBox(height: 6),
      Container(padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border, width: 1.5)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: value, hint: Text('State', style: GoogleFonts.barlow(fontSize: 14, color: const Color(0xFF3A5070))), dropdownColor: surface, style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary), isExpanded: true, items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: onChange))),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final loadNumber = widget.loadData['loadNumber'] ?? 'YU-0000';
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 36, height: 36, decoration: BoxDecoration(color: orange, shape: BoxShape.circle), child: const Center(child: Icon(Icons.chevron_left, color: Colors.white, size: 22)))),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Edit Load', style: GoogleFonts.barlowCondensed(fontSize: 24, fontWeight: FontWeight.w900, color: textPrimary)),
                Text(loadNumber, style: GoogleFonts.barlowCondensed(fontSize: 14, fontWeight: FontWeight.w700, color: orange, letterSpacing: 1)),
              ]),
            ]),
            const SizedBox(height: 20),

            Text('STATUS', style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: textMuted)),
            const SizedBox(height: 8),
            Row(children: ['invoiced', 'unpaid', 'paid'].map((s) {
              final isSelected = _status == s;
              final color = s == 'paid' ? success : s == 'invoiced' ? info : orange;
              return GestureDetector(
                onTap: () => setState(() => _status = s),
                child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: isSelected ? color.withValues(alpha: 0.15) : surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? color : border)),
                  child: Text(s.toUpperCase(), style: GoogleFonts.barlowCondensed(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1, color: isSelected ? color : textMuted))),
              );
            }).toList()),

            const SizedBox(height: 16),
            _field('RATE (USD)', _rateController, TextInputType.number),
            const SizedBox(height: 10),
            Row(children: [Expanded(child: _field('MILEAGE', _mileageController, TextInputType.number)), const SizedBox(width: 10), Expanded(child: _field('EXPENSES', _expensesController, TextInputType.number))]),
            const SizedBox(height: 10),
            Row(children: [Expanded(child: _dropdown('PICK UP STATE', _pickupState, (v) => setState(() => _pickupState = v))), const SizedBox(width: 10), Expanded(child: _dropdown('DELIVERY STATE', _deliveryState, (v) => setState(() => _deliveryState = v)))]),
            const SizedBox(height: 10),
            _field('BROKER EMAIL', _brokerEmailController, TextInputType.emailAddress),
            const SizedBox(height: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('NOTES', style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: textMuted)),
              const SizedBox(height: 6),
              TextField(controller: _notesController, maxLines: 3, style: GoogleFonts.barlow(fontSize: 14, color: textPrimary), decoration: InputDecoration(hintText: 'Notes...', hintStyle: GoogleFonts.barlow(fontSize: 13, color: const Color(0xFF3A5070)), filled: true, fillColor: surface, contentPadding: const EdgeInsets.all(14), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1C2E45), width: 1.5)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF5921E), width: 1.5)))),
            ]),

            const SizedBox(height: 20),
            Text('DOCUMENTS', style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: textMuted)),
            const SizedBox(height: 8),

            if (_isUploading) Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Color(0xFFF5921E), strokeWidth: 2)),
                const SizedBox(width: 8),
                Text('Uploading...', style: GoogleFonts.barlow(fontSize: 12, color: textMuted)),
              ]),
            ),

            _buildDocPhoto(_rateConUrl, 'RATE CONFIRMATION', Icons.description, () async {
              final url = await _uploadPhoto('ratcon');
              if (url != null) setState(() => _rateConUrl = url);
            }),
            const SizedBox(height: 8),
            _buildDocPhoto(_bolUrl, 'BILL OF LADING', Icons.article, () async {
              final url = await _uploadPhoto('bol');
              if (url != null) setState(() => _bolUrl = url);
            }),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _freightUrls.isNotEmpty ? success : border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    Icon(Icons.photo_library, color: _freightUrls.isNotEmpty ? success : textMuted, size: 16),
                    const SizedBox(width: 8),
                    Text('FREIGHT PHOTOS (' + _freightUrls.length.toString() + ')', style: GoogleFonts.barlowCondensed(fontSize: 12, fontWeight: FontWeight.w700, color: _freightUrls.isNotEmpty ? textPrimary : textMuted)),
                  ]),
                  GestureDetector(
                    onTap: _addFreightPhoto,
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(8)), child: Text('+ ADD', style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w900, color: background))),
                  ),
                ]),
                if (_freightUrls.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _freightUrls.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(_freightUrls[i], width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: border, child: const Icon(Icons.broken_image, color: Colors.white54))),
                        ),
                      ),
                    ),
                  ),
                ],
              ]),
            ),

            const SizedBox(height: 8),
            _buildDocPhoto(_podUrl, 'PROOF OF DELIVERY', Icons.check_circle, () async {
              final url = await _uploadPhoto('pod');
              if (url != null) setState(() => _podUrl = url);
            }),

            const SizedBox(height: 20),

            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resendPacket,
                  style: OutlinedButton.styleFrom(side: BorderSide(color: orange), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text('RESEND PACKET', style: GoogleFonts.barlowCondensed(fontSize: 14, fontWeight: FontWeight.w800, color: orange, letterSpacing: 1)),
                ),
              ),
            ]),

            const SizedBox(height: 10),
            SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _isLoading ? null : _save, style: ElevatedButton.styleFrom(backgroundColor: orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text('SAVE CHANGES', style: GoogleFonts.barlowCondensed(fontSize: 18, fontWeight: FontWeight.w900, color: background, letterSpacing: 2)))),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}
