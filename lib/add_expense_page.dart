import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedCategory;
  String? _receiptUrl;
  bool _isLoading = false;
  bool _isUploadingReceipt = false;

  static const Color background = Color(0xFF0B1628);
  static const Color surface = Color(0xFF122035);
  static const Color border = Color(0xFF1C2E45);
  static const Color orange = Color(0xFFF5921E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF5A7A9A);
  static const Color success = Color(0xFF4ADE80);

  final List<Map<String, String>> _categories = [
    {'icon': 'F', 'label': 'Fuel'},
    {'icon': 'R', 'label': 'Repairs'},
    {'icon': 'T', 'label': 'Tolls'},
    {'icon': 'P', 'label': 'Permits'},
    {'icon': 'L', 'label': 'Lodging'},
    {'icon': 'LU', 'label': 'Lumper'},
    {'icon': 'O', 'label': 'Other'},
  ];

  Future<void> _uploadReceipt() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (picked == null) return;
      setState(() => _isUploadingReceipt = true);
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? 'unknown';
      final fileName = uid + '_receipt_' + DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
      final ref = FirebaseStorage.instance.ref().child('receipts/' + uid + '/' + fileName);
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();
      setState(() {
        _receiptUrl = url;
        _isUploadingReceipt = false;
      });
    } catch (e) {
      setState(() => _isUploadingReceipt = false);
    }
  }

  Future<void> _saveExpense() async {
    if (_amountController.text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter amount and select category'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance.collection('expenses').add({
        'userId': user.uid,
        'amount': double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0,
        'category': _selectedCategory,
        'note': _noteController.text.trim(),
        'receiptUrl': _receiptUrl ?? '',
        'hasReceipt': _receiptUrl != null,
        'date': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense saved'), backgroundColor: Color(0xFF4ADE80)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ' + e.toString()), backgroundColor: Colors.red),
        );
      }
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(width: 36, height: 36, decoration: BoxDecoration(color: orange, shape: BoxShape.circle), child: const Center(child: Icon(Icons.chevron_left, color: Colors.white, size: 22))),
                  ),
                  const SizedBox(width: 12),
                  Text('New Expense', style: GoogleFonts.barlowCondensed(fontSize: 24, fontWeight: FontWeight.w900, color: textPrimary)),
                ],
              ),
              const SizedBox(height: 20),

              Text('AMOUNT', style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: textMuted)),
              const SizedBox(height: 6),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.barlowCondensed(fontSize: 36, fontWeight: FontWeight.w900, color: orange),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: GoogleFonts.barlowCondensed(fontSize: 36, color: const Color(0xFF2A4060)),
                  prefixText: 'USD ',
                  prefixStyle: GoogleFonts.barlowCondensed(fontSize: 24, fontWeight: FontWeight.w900, color: orange),
                  filled: true,
                  fillColor: surface,
                  contentPadding: const EdgeInsets.all(14),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF5921E), width: 1.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF5921E), width: 1.5)),
                ),
              ),

              const SizedBox(height: 20),

              Text('CATEGORY', style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: textMuted)),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.1),
                itemCount: _categories.length,
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  final isSelected = _selectedCategory == cat['label'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat['label']),
                    child: Container(
                      decoration: BoxDecoration(color: isSelected ? orange : surface, borderRadius: BorderRadius.circular(10), border: isSelected ? null : Border.all(color: border)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(cat['icon']!, style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w900, color: isSelected ? background : orange)),
                          const SizedBox(height: 2),
                          Text(cat['label']!, style: GoogleFonts.barlowCondensed(fontSize: 9, fontWeight: FontWeight.w800, color: isSelected ? background : textMuted), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              Text('NOTE (OPTIONAL)', style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: textMuted)),
              const SizedBox(height: 6),
              TextField(
                controller: _noteController,
                style: GoogleFonts.barlow(fontSize: 14, color: textPrimary),
                decoration: InputDecoration(hintText: 'Station name, location, notes...', hintStyle: GoogleFonts.barlow(fontSize: 14, color: const Color(0xFF3A5070)), filled: true, fillColor: surface, contentPadding: const EdgeInsets.all(14), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1C2E45), width: 1.5)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF5921E), width: 1.5))),
              ),

              const SizedBox(height: 16),

              Text('RECEIPT', style: GoogleFonts.barlowCondensed(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: textMuted)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _receiptUrl != null ? success : border)),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(_receiptUrl != null ? Icons.check_circle : Icons.receipt_long, color: _receiptUrl != null ? success : textMuted, size: 20),
                          const SizedBox(width: 10),
                          Text(_receiptUrl != null ? 'Receipt uploaded' : 'Got a receipt? Upload it.', style: GoogleFonts.barlow(fontSize: 13, color: _receiptUrl != null ? success : textMuted)),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFF1C2E45)),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _isUploadingReceipt ? null : _uploadReceipt,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(color: _receiptUrl != null ? success.withValues(alpha: 0.15) : orange, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12))),
                              child: Center(
                                child: _isUploadingReceipt
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Text(_receiptUrl != null ? 'REPLACE RECEIPT' : 'YUPLOAD RECEIPT', style: GoogleFonts.barlowCondensed(fontSize: 14, fontWeight: FontWeight.w900, color: _receiptUrl != null ? success : background, letterSpacing: 1)),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _receiptUrl = null),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: const BoxDecoration(borderRadius: BorderRadius.only(bottomRight: Radius.circular(12))),
                              child: Center(child: Text('NOPE', style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF5A7A9A), letterSpacing: 2))),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveExpense,
                  style: ElevatedButton.styleFrom(backgroundColor: orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('YUPLOAD', style: GoogleFonts.barlowCondensed(fontSize: 22, fontWeight: FontWeight.w900, color: background, letterSpacing: 3)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
