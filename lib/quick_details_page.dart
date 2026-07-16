import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'yuploaded_page.dart';
import 'invoice_generator.dart';
import 'email_service.dart';
import 'payment_page.dart';

class QuickDetailsPage extends StatefulWidget {
  final String? rateConUrl;
  final String? bolUrl;
  final List<String> freightUrls;
  final String? podUrl;

  const QuickDetailsPage({
    super.key,
    this.rateConUrl,
    this.bolUrl,
    this.freightUrls = const [],
    this.podUrl,
  });

  @override
  State<QuickDetailsPage> createState() => _QuickDetailsPageState();
}

class _QuickDetailsPageState extends State<QuickDetailsPage> {
  final _mileageController = TextEditingController();
  final _expensesController = TextEditingController();
  final _notesController = TextEditingController();
  final _brokerEmailController = TextEditingController();
  final _rateController = TextEditingController();
  final _pickupZipController = TextEditingController();
  final _deliveryZipController = TextEditingController();
  String? _pickupState;
  String? _deliveryState;
  String _pickupCity = '';
  String _deliveryCity = '';
  bool _isLoading = false;
  bool _isLookingUpZip = false;
  String _savedDispatcherEmail = '';

  static const Color background = Color(0xFF0B1628);
  static const Color surface = Color(0xFF122035);
  static const Color border = Color(0xFF1C2E45);
  static const Color orange = Color(0xFFF5921E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF5A7A9A);
  static const Color success = Color(0xFF4ADE80);
  static const Color danger = Color(0xFFEF4444);

  final List<String> _states = ['AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA','HI','ID','IL','IN','IA','KS','KY','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ','NM','NY','NC','ND','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VT','VA','WA','WV','WI','WY'];

  @override
  void initState() {
    super.initState();
    _loadSavedEmails();
  }

  Future<void> _loadSavedEmails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data() ?? {};
    setState(() {
      _savedDispatcherEmail = data['dispatcherEmail'] ?? '';
      if (_brokerEmailController.text.isEmpty) _brokerEmailController.text = data['lastBrokerEmail'] ?? '';
    });
  }

  Future<void> _lookupZip(String zip, bool isPickup) async {
    if (zip.length != 5) return;
    setState(() => _isLookingUpZip = true);
    try {
      final response = await http.get(Uri.parse('https://api.zippopotam.us/us/' + zip));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final places = data['places'] as List;
        if (places.isNotEmpty) {
          final place = places[0];
          final city = place['place name'] as String;
          final state = place['state abbreviation'] as String;
          setState(() {
            if (isPickup) { _pickupCity = city; _pickupState = state; }
            else { _deliveryCity = city; _deliveryState = state; }
          });
        }
      }
    } catch (e) {
      // ZIP lookup failed silently - driver can still select state manually
    } finally {
      setState(() => _isLookingUpZip = false);
    }
  }

  bool _validateFields() {
    if (_rateController.text.isEmpty) { _showError('Please enter the agreed rate'); return false; }
    if (_pickupState == null) { _showError('Please enter pickup ZIP or select state'); return false; }
    if (_deliveryState == null) { _showError('Please enter delivery ZIP or select state'); return false; }
    if (_mileageController.text.isEmpty) { _showError('Please enter mileage'); return false; }
    return true;
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: danger));

  Future<bool> _checkFreeLimit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data() ?? {};
    final isFree = data['isFree'] ?? true;
    final totalLoads = (data['totalLoads'] ?? 0) as int;
    if (isFree && totalLoads >= 3) {
      if (mounted) showDialog(context: context, builder: (ctx) => AlertDialog(
        backgroundColor: surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Free limit reached', style: GoogleFonts.barlowCondensed(fontSize: 22, fontWeight: FontWeight.w900, color: textPrimary)),
        content: Text('You have used your 3 free loads. Upgrade for unlimited loads.', style: GoogleFonts.barlow(fontSize: 14, color: textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('NOPE', style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w900, color: textMuted))),
          TextButton(onPressed: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentPage())); }, child: Text('UPGRADE', style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w900, color: orange))),
        ],
      ));
      return false;
    }
    return true;
  }

  Future<void> _yupload() async {
    if (!_validateFields()) return;
    final canUpload = await _checkFreeLimit();
    if (!canUpload) return;
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data() ?? {};
      final totalLoads = (data['totalLoads'] ?? 0) as int;
      final firstName = data['firstName'] ?? 'Driver';
      final lastName = data['lastName'] ?? '';
      final driverName = firstName + ' ' + lastName;
      final mcNumber = data['mcDot'] ?? '';
      final mcClean = mcNumber.replaceAll(RegExp(r'[^0-9]'), '');
      final mcSuffix = mcClean.length >= 4 ? mcClean.substring(mcClean.length - 4) : mcClean.padLeft(4, '0');
      final loadNumber = 'YU-' + mcSuffix + '-' + (totalLoads + 1).toString().padLeft(4, '0');
      final brokerEmail = _brokerEmailController.text.trim();
      final rate = double.tryParse(_rateController.text.replaceAll(',', '')) ?? 0.0;
      final pickupZip = _pickupZipController.text.trim();
      final deliveryZip = _deliveryZipController.text.trim();
      final routeLabel = _pickupCity.isNotEmpty ? _pickupCity + ' ' + (_pickupState ?? '') + ' to ' + _deliveryCity + ' ' + (_deliveryState ?? '') : (_pickupState ?? '') + ' to ' + (_deliveryState ?? '');

      await FirebaseFirestore.instance.collection('loads').add({
        'userId': user.uid,
        'loadNumber': loadNumber,
        'mileage': int.tryParse(_mileageController.text) ?? 0,
        'expenses': double.tryParse(_expensesController.text.replaceAll(',', '')) ?? 0.0,
        'pickupState': _pickupState ?? '',
        'deliveryState': _deliveryState ?? '',
        'pickupCity': _pickupCity,
        'deliveryCity': _deliveryCity,
        'pickupZip': pickupZip,
        'deliveryZip': deliveryZip,
        'routeLabel': routeLabel,
        'notes': _notesController.text.trim(),
        'brokerEmail': brokerEmail,
        'dispatcherEmail': _savedDispatcherEmail,
        'rate': rate,
        'status': 'invoiced',
        'brokerConfirmed': false,
        'rateConUrl': widget.rateConUrl ?? '',
        'bolUrl': widget.bolUrl ?? '',
        'freightUrls': widget.freightUrls,
        'podUrl': widget.podUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'totalLoads': FieldValue.increment(1),
        if (brokerEmail.isNotEmpty) 'lastBrokerEmail': brokerEmail,
      });

      if (brokerEmail.isNotEmpty) await EmailService.sendInvoice(brokerEmail: brokerEmail, loadNumber: loadNumber, pickupState: _pickupCity.isNotEmpty ? _pickupCity + ' ' + (_pickupState ?? '') : (_pickupState ?? ''), deliveryState: _deliveryCity.isNotEmpty ? _deliveryCity + ' ' + (_deliveryState ?? '') : (_deliveryState ?? ''), rate: 'USD ' + rate.toStringAsFixed(2), driverName: driverName, mcNumber: mcNumber);
      if (_savedDispatcherEmail.isNotEmpty) await EmailService.sendDispatcherPacket(dispatcherEmail: _savedDispatcherEmail, loadNumber: loadNumber, pickupState: _pickupCity.isNotEmpty ? _pickupCity + ' ' + (_pickupState ?? '') : (_pickupState ?? ''), deliveryState: _deliveryCity.isNotEmpty ? _deliveryCity + ' ' + (_deliveryState ?? '') : (_deliveryState ?? ''), driverName: driverName);

      if (mounted) {
        await InvoiceGenerator.generateAndShare(loadNumber: loadNumber, driverName: driverName, mcNumber: mcNumber, pickupState: _pickupCity.isNotEmpty ? _pickupCity + ' ' + (_pickupState ?? '') : (_pickupState ?? ''), deliveryState: _deliveryCity.isNotEmpty ? _deliveryCity + ' ' + (_deliveryState ?? '') : (_deliveryState ?? ''), rate: rate, brokerEmail: brokerEmail, context: context);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => YUPLOADEDPage(loadNumber: loadNumber)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ' + e.toString()), backgroundColor: danger));
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 36, height: 36, decoration: BoxDecoration(color: orange, shape: BoxShape.circle), child: const Center(child: Icon(Icons.chevron_left, color: Colors.white, size: 22)))),
              const SizedBox(width: 12),
              Text('Quick Details', style: GoogleFonts.barlowCondensed(fontSize: 24, fontWeight: FontWeight.w900, color: textPrimary)),
            ]),
            const SizedBox(height: 16),
            Row(children: List.generate(5, (i) => Expanded(child: Container(height: 4, margin: const EdgeInsets.only(right: 6), decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(2)))))),
            const SizedBox(height: 16),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: success.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: success.withValues(alpha: 0.2))), child: Row(children: [const Icon(Icons.check_circle, color: Color(0xFF4ADE80), size: 16), const SizedBox(width: 8), Text('Docs uploaded - fill in the details', style: GoogleFonts.barlow(fontSize: 13, color: success, fontWeight: FontWeight.w600))])),
            const SizedBox(height: 16),

            _reqField('AGREED RATE (USD) *', '0', _rateController, TextInputType.number),
            const SizedBox(height: 10),
            Row(children: [Expanded(child: _reqField('MILEAGE *', '0', _mileageController, TextInputType.number)), const SizedBox(width: 10), Expanded(child: _optField('EXPENSES', '0', _expensesController, TextInputType.number))]),
            Padding(padding: const EdgeInsets.only(top: 4), child: Text('Enter miles from PC Miler, Google, or odometer', style: GoogleFonts.barlow(fontSize: 10, color: textMuted))),
            const SizedBox(height: 16),

            // ZIP TO ZIP SECTION
            Text('ROUTE', style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: textMuted)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('PICKUP ZIP', style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: orange)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _pickupZipController,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    style: GoogleFonts.barlowCondensed(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimary),
                    onChanged: (val) { if (val.length == 5) _lookupZip(val, true); },
                    decoration: InputDecoration(
                      hintText: '00000',
                      hintStyle: GoogleFonts.barlow(fontSize: 13, color: const Color(0xFF3A5070)),
                      counterText: '',
                      filled: true, fillColor: surface, contentPadding: const EdgeInsets.all(14),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _pickupState != null ? orange : border, width: 1.5)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF5921E), width: 1.5)),
                    ),
                  ),
                  if (_pickupCity.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(_pickupCity + ', ' + (_pickupState ?? ''), style: GoogleFonts.barlow(fontSize: 11, color: success))),
                ]),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('DELIVERY ZIP', style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: orange)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _deliveryZipController,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    style: GoogleFonts.barlowCondensed(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimary),
                    onChanged: (val) { if (val.length == 5) _lookupZip(val, false); },
                    decoration: InputDecoration(
                      hintText: '00000',
                      hintStyle: GoogleFonts.barlow(fontSize: 13, color: const Color(0xFF3A5070)),
                      counterText: '',
                      filled: true, fillColor: surface, contentPadding: const EdgeInsets.all(14),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _deliveryState != null ? orange : border, width: 1.5)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF5921E), width: 1.5)),
                    ),
                  ),
                  if (_deliveryCity.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(_deliveryCity + ', ' + (_deliveryState ?? ''), style: GoogleFonts.barlow(fontSize: 11, color: success))),
                ]),
              ),
            ]),
            if (_isLookingUpZip) Padding(padding: const EdgeInsets.only(top: 6), child: Row(children: [const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(color: Color(0xFFF5921E), strokeWidth: 2)), const SizedBox(width: 8), Text('Looking up city...', style: GoogleFonts.barlow(fontSize: 11, color: textMuted))])),

            const SizedBox(height: 8),
            Text('Or select states manually:', style: GoogleFonts.barlow(fontSize: 11, color: textMuted)),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: _stateDD('PICK UP STATE *', _pickupState, (v) => setState(() => _pickupState = v))),
              const SizedBox(width: 10),
              Expanded(child: _stateDD('DELIVERY STATE *', _deliveryState, (v) => setState(() => _deliveryState = v))),
            ]),

            const SizedBox(height: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('NOTES (OPTIONAL)', style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: textMuted)),
              const SizedBox(height: 6),
              TextField(controller: _notesController, maxLines: 3, style: GoogleFonts.barlow(fontSize: 14, color: textPrimary), decoration: InputDecoration(hintText: 'Anything worth remembering...', hintStyle: GoogleFonts.barlow(fontSize: 13, color: const Color(0xFF3A5070)), filled: true, fillColor: surface, contentPadding: const EdgeInsets.all(14), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1C2E45), width: 1.5)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF5921E), width: 1.5)))),
            ]),
            const SizedBox(height: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('BROKER EMAIL', style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: textMuted)),
              const SizedBox(height: 6),
              TextField(controller: _brokerEmailController, keyboardType: TextInputType.emailAddress, style: GoogleFonts.barlow(fontSize: 14, color: textPrimary), decoration: InputDecoration(hintText: 'broker@company.com', hintStyle: GoogleFonts.barlow(fontSize: 13, color: const Color(0xFF3A5070)), filled: true, fillColor: surface, contentPadding: const EdgeInsets.all(14), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1C2E45), width: 1.5)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF5921E), width: 1.5)))),
            ]),
            if (_savedDispatcherEmail.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: orange.withValues(alpha: 0.3))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('DISPATCHER', style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: orange)),
                  const SizedBox(height: 4),
                  Text(_savedDispatcherEmail, style: GoogleFonts.barlow(fontSize: 13, color: textMuted)),
                ]),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)), child: Text('AUTO SEND', style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w800, color: success))),
              ])),
            ],
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, height: 64, child: ElevatedButton(
              onPressed: _isLoading ? null : _yupload,
              style: ElevatedButton.styleFrom(backgroundColor: orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text('YUPLOAD', style: GoogleFonts.barlowCondensed(fontSize: 26, fontWeight: FontWeight.w900, color: background, letterSpacing: 3)),
            )),
            const SizedBox(height: 8),
            Center(child: Text('* Required fields must be filled to YUPLOAD', style: GoogleFonts.barlow(fontSize: 11, color: textMuted))),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  Widget _reqField(String label, String hint, TextEditingController ctrl, TextInputType type) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: orange)),
      const SizedBox(height: 6),
      TextField(controller: ctrl, keyboardType: type, style: GoogleFonts.barlowCondensed(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimary), decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.barlow(fontSize: 13, color: const Color(0xFF3A5070)), filled: true, fillColor: surface, contentPadding: const EdgeInsets.all(14), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF5921E), width: 1.5)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF5921E), width: 1.5)))),
    ]);
  }

  Widget _optField(String label, String hint, TextEditingController ctrl, TextInputType type) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: textMuted)),
      const SizedBox(height: 6),
      TextField(controller: ctrl, keyboardType: type, style: GoogleFonts.barlowCondensed(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimary), decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.barlow(fontSize: 13, color: const Color(0xFF3A5070)), filled: true, fillColor: surface, contentPadding: const EdgeInsets.all(14), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1C2E45), width: 1.5)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF5921E), width: 1.5)))),
    ]);
  }

  Widget _stateDD(String label, String? value, Function(String?) onChange) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: textMuted)),
      const SizedBox(height: 6),
      Container(padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: value != null ? orange : border, width: 1.5)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: value, hint: Text('State', style: GoogleFonts.barlow(fontSize: 14, color: const Color(0xFF3A5070))), dropdownColor: surface, style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary), isExpanded: true, items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: onChange))),
    ]);
  }
}
