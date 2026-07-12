import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// This page handles broker confirmation when they click the link in the email
// It can also be triggered manually from within the app for testing

class ConfirmLoadPage extends StatefulWidget {
  final String loadNumber;
  const ConfirmLoadPage({super.key, required this.loadNumber});

  @override
  State<ConfirmLoadPage> createState() => _ConfirmLoadPageState();
}

class _ConfirmLoadPageState extends State<ConfirmLoadPage> {
  bool _isLoading = true;
  bool _confirmed = false;
  String _message = 'Confirming load...';

  static const Color background = Color(0xFF0B1628);
  static const Color surface = Color(0xFF122035);
  static const Color orange = Color(0xFFF5921E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF5A7A9A);
  static const Color success = Color(0xFF4ADE80);

  @override
  void initState() {
    super.initState();
    _confirmLoad();
  }

  Future<void> _confirmLoad() async {
    try {
      // Find the load by load number
      final snapshot = await FirebaseFirestore.instance
          .collection('loads')
          .where('loadNumber', isEqualTo: widget.loadNumber)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _message = 'Load not found.';
        });
        return;
      }

      final loadDoc = snapshot.docs.first;
      final loadData = loadDoc.data();
      final userId = loadData['userId'] as String?;
      final alreadyConfirmed = loadData['brokerConfirmed'] ?? false;

      if (alreadyConfirmed) {
        setState(() {
          _isLoading = false;
          _confirmed = true;
          _message = 'This load was already confirmed.';
        });
        return;
      }

      // Mark load as broker confirmed
      await FirebaseFirestore.instance.collection('loads').doc(loadDoc.id).update({
        'brokerConfirmed': true,
        'brokerConfirmedAt': FieldValue.serverTimestamp(),
      });

      // Increment verified loads counter on driver profile
      if (userId != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'verifiedLoads': FieldValue.increment(1),
        });
      }

      setState(() {
        _isLoading = false;
        _confirmed = true;
        _message = 'Load ' + widget.loadNumber + ' confirmed.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Error confirming load. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading) ...[
                  const CircularProgressIndicator(color: Color(0xFFF5921E)),
                  const SizedBox(height: 24),
                  Text('Confirming...', style: GoogleFonts.barlowCondensed(fontSize: 20, fontWeight: FontWeight.w700, color: textMuted)),
                ] else ...[
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: _confirmed ? success.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: _confirmed ? success : Colors.red, width: 2),
                    ),
                    child: Center(child: Icon(_confirmed ? Icons.check : Icons.error_outline, color: _confirmed ? success : Colors.red, size: 40)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _confirmed ? 'Confirmed.' : 'Not Found.',
                    style: GoogleFonts.barlowCondensed(fontSize: 40, fontWeight: FontWeight.w900, color: _confirmed ? success : Colors.red),
                  ),
                  const SizedBox(height: 12),
                  Text(_message, style: GoogleFonts.barlow(fontSize: 16, color: textMuted), textAlign: TextAlign.center),
                  if (_confirmed) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
                      child: Column(children: [
                        const Icon(Icons.shield, color: Color(0xFFF5921E), size: 24),
                        const SizedBox(height: 8),
                        Text('This confirmation counts toward the driver\'s YUPLOADED Verified status.', style: GoogleFonts.barlow(fontSize: 13, color: textMuted), textAlign: TextAlign.center),
                        const SizedBox(height: 4),
                        Text('Earned. Not bought.', style: GoogleFonts.barlowCondensed(fontSize: 14, fontWeight: FontWeight.w800, color: orange)),
                      ]),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
