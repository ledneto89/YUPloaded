import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class TaxesPage extends StatefulWidget {
  const TaxesPage({super.key});
  @override
  State<TaxesPage> createState() => _TaxesPageState();
}

class _TaxesPageState extends State<TaxesPage> {
  int _selectedYear = DateTime.now().year;
  bool _isExporting = false;

  static const Color background = Color(0xFF0B1628);
  static const Color surface = Color(0xFF122035);
  static const Color border = Color(0xFF1C2E45);
  static const Color orange = Color(0xFFF5921E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF5A7A9A);
  static const Color success = Color(0xFF4ADE80);

  final Map<String, IconData> _categoryIcons = {
    'Fuel': Icons.local_gas_station,
    'Repairs': Icons.build,
    'Tolls': Icons.toll,
    'Permits': Icons.description,
    'Lodging': Icons.hotel,
    'Lumper': Icons.person,
    'Other': Icons.more_horiz,
  };

  Future<void> _exportCSV(List<QueryDocumentSnapshot> loads, List<QueryDocumentSnapshot> expenses) async {
    setState(() => _isExporting = true);
    try {
      final buffer = StringBuffer();

      // Loads section
      buffer.writeln('LOADS - ' + _selectedYear.toString());
      buffer.writeln('Load Number,Date,Pickup,Delivery,Rate,Mileage,Expenses,Status,Broker Confirmed');
      for (final doc in loads) {
        final data = doc.data() as Map<String, dynamic>;
        final date = data['createdAt'] != null ? (data['createdAt'] as dynamic).toDate().toString().substring(0, 10) : '';
        final pickup = (data['pickupCity'] ?? '') + ' ' + (data['pickupState'] ?? '');
        final delivery = (data['deliveryCity'] ?? '') + ' ' + (data['deliveryState'] ?? '');
        buffer.writeln([
          data['loadNumber'] ?? '',
          date,
          pickup.trim(),
          delivery.trim(),
          (data['rate'] ?? 0).toString(),
          (data['mileage'] ?? 0).toString(),
          (data['expenses'] ?? 0).toString(),
          data['status'] ?? '',
          (data['brokerConfirmed'] ?? false).toString(),
        ].join(','));
      }

      buffer.writeln('');
      buffer.writeln('EXPENSES - ' + _selectedYear.toString());
      buffer.writeln('Date,Category,Amount,Note');
      for (final doc in expenses) {
        final data = doc.data() as Map<String, dynamic>;
        final date = data['createdAt'] != null ? (data['createdAt'] as dynamic).toDate().toString().substring(0, 10) : '';
        buffer.writeln([
          date,
          data['category'] ?? '',
          (data['amount'] ?? 0).toString(),
          (data['note'] ?? '').replaceAll(',', ' '),
        ].join(','));
      }

      final dir = await getTemporaryDirectory();
      final file = File(dir.path + '/YUPLOADED_' + _selectedYear.toString() + '_taxes.csv');
      await file.writeAsString(buffer.toString());

      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'YUPLOADED Tax Export ' + _selectedYear.toString(),
        sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : const Rect.fromLTWH(0, 0, 393, 852),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: ' + e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportPDF(
    List<QueryDocumentSnapshot> loads,
    List<QueryDocumentSnapshot> expenses,
    double totalIncome,
    double totalExpenses,
    int totalMiles,
    String driverName,
    String mcNumber,
    Map<String, double> categoryTotals,
  ) async {
    setState(() => _isExporting = true);
    try {
      final pdf = pw.Document();
      final netProfit = totalIncome - totalExpenses;
      final mileageDeduction = totalMiles * 0.70;

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) => [
          // HEADER
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('YUPLOADED', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('F5921E'))),
              pw.Text('Tax Summary ' + _selectedYear.toString(), style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600)),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text(driverName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('MC-' + mcNumber, style: const pw.TextStyle(fontSize: 12)),
              pw.Text('Generated: ' + DateTime.now().toString().substring(0, 10), style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
            ]),
          ]),

          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 16),

          // SUMMARY
          pw.Text('ANNUAL SUMMARY', style: pw.TextStyle(fontSize: 11, color: PdfColors.grey500, letterSpacing: 2)),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(color: PdfColor.fromHex('F5F5F5'), borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceAround, children: [
              pw.Column(children: [
                pw.Text('GROSS INCOME', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
                pw.SizedBox(height: 4),
                pw.Text('USD ' + totalIncome.toStringAsFixed(2), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('16A34A'))),
              ]),
              pw.Column(children: [
                pw.Text('TOTAL EXPENSES', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
                pw.SizedBox(height: 4),
                pw.Text('USD ' + totalExpenses.toStringAsFixed(2), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('F5921E'))),
              ]),
              pw.Column(children: [
                pw.Text('NET PROFIT', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
                pw.SizedBox(height: 4),
                pw.Text('USD ' + netProfit.toStringAsFixed(2), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ]),
            ]),
          ),

          pw.SizedBox(height: 16),

          // MILEAGE
          pw.Text('MILEAGE DEDUCTION', style: pw.TextStyle(fontSize: 11, color: PdfColors.grey500, letterSpacing: 2)),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Estimated Loaded Miles', style: const pw.TextStyle(fontSize: 12)),
                pw.Text(totalMiles.toString() + ' miles @ USD 0.70/mi (IRS rate)', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
              ]),
              pw.Text('USD ' + mileageDeduction.toStringAsFixed(2), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('16A34A'))),
            ]),
          ),

          pw.SizedBox(height: 16),

          // EXPENSE BREAKDOWN
          if (categoryTotals.isNotEmpty) ...[
            pw.Text('EXPENSE BREAKDOWN', style: pw.TextStyle(fontSize: 11, color: PdfColors.grey500, letterSpacing: 2)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey200),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF5F5F5)),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
                  ],
                ),
                ...categoryTotals.entries.map((entry) => pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(entry.key, style: const pw.TextStyle(fontSize: 11))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('USD ' + entry.value.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 11))),
                ])),
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          // LOAD LIST
          pw.Text('LOAD HISTORY (' + loads.length.toString() + ' loads)', style: pw.TextStyle(fontSize: 11, color: PdfColors.grey500, letterSpacing: 2)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey200),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF5F5F5)),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Load #', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Route', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Rate', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Miles', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                ],
              ),
              ...loads.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final pickup = (data['pickupCity'] ?? data['pickupState'] ?? '');
                final delivery = (data['deliveryCity'] ?? data['deliveryState'] ?? '');
                return pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(data['loadNumber'] ?? '', style: const pw.TextStyle(fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(pickup + ' → ' + delivery, style: const pw.TextStyle(fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('USD ' + (data['rate'] ?? 0).toString(), style: const pw.TextStyle(fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text((data['mileage'] ?? 0).toString(), style: const pw.TextStyle(fontSize: 9))),
                ]);
              }),
            ],
          ),

          pw.SizedBox(height: 24),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text('Generated by YUPLOADED - yuploaded.com', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey400)),
          pw.Text('Mileage estimates based on ZIP codes logged. Consult a tax professional for filing.', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey400)),
        ],
      ));

      final dir = await getTemporaryDirectory();
      final file = File(dir.path + '/YUPLOADED_' + _selectedYear.toString() + '_tax_summary.pdf');
      await file.writeAsBytes(await pdf.save());

      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'YUPLOADED Tax Summary ' + _selectedYear.toString(),
        sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : const Rect.fromLTWH(0, 0, 393, 852),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: ' + e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 36, height: 36, decoration: BoxDecoration(color: orange, shape: BoxShape.circle), child: const Center(child: Icon(Icons.chevron_left, color: Colors.white, size: 22)))),
              const SizedBox(width: 12),
              Text('Taxes', style: GoogleFonts.barlowCondensed(fontSize: 32, fontWeight: FontWeight.w900, color: textPrimary, letterSpacing: -0.5)),
            ]),
            const SizedBox(height: 16),

            Row(
              children: [2024, 2025, 2026].map((year) {
                final isSelected = _selectedYear == year;
                return GestureDetector(
                  onTap: () => setState(() => _selectedYear = year),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? orange.withValues(alpha: 0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected ? Border.all(color: orange) : null,
                    ),
                    child: Text(year.toString(), style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w800, color: isSelected ? orange : textMuted)),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            if (user != null)
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                builder: (context, userSnapshot) {
                  final userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                  final driverName = (userData['firstName'] ?? '') + ' ' + (userData['lastName'] ?? '');
                  final mcNumber = userData['mcDot'] ?? '';

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('loads').where('userId', isEqualTo: user.uid).snapshots(),
                    builder: (context, loadsSnapshot) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('expenses').where('userId', isEqualTo: user.uid).snapshots(),
                        builder: (context, expensesSnapshot) {
                          final allLoads = loadsSnapshot.data?.docs ?? [];
                          final allExpenses = expensesSnapshot.data?.docs ?? [];
                          final now = DateTime.now();

                          final yearLoads = allLoads.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final createdAt = data['createdAt'];
                            if (createdAt == null) return false;
                            try { final date = (createdAt as dynamic).toDate() as DateTime; return date.year == _selectedYear; } catch (e) { return false; }
                          }).toList();

                          final yearExpenses = allExpenses.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final createdAt = data['createdAt'];
                            if (createdAt == null) return false;
                            try { final date = (createdAt as dynamic).toDate() as DateTime; return date.year == _selectedYear; } catch (e) { return false; }
                          }).toList();

                          final totalIncome = yearLoads.fold<double>(0, (sum, doc) { final data = doc.data() as Map<String, dynamic>; return sum + ((data['rate'] ?? 0.0) as num).toDouble(); });
                          final totalExpenses = yearExpenses.fold<double>(0, (sum, doc) { final data = doc.data() as Map<String, dynamic>; return sum + ((data['amount'] ?? 0.0) as num).toDouble(); });
                          final totalMiles = yearLoads.fold<int>(0, (sum, doc) { final data = doc.data() as Map<String, dynamic>; return sum + ((data['mileage'] ?? 0) as num).toInt(); });
                          final netProfit = totalIncome - totalExpenses;
                          final mileageDeduction = totalMiles * 0.70;

                          final Map<String, double> categoryTotals = {};
                          for (final doc in yearExpenses) {
                            final data = doc.data() as Map<String, dynamic>;
                            final cat = data['category'] ?? 'Other';
                            final amount = ((data['amount'] ?? 0.0) as num).toDouble();
                            categoryTotals[cat] = (categoryTotals[cat] ?? 0) + amount;
                          }

                          return Column(children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
                              child: Column(children: [
                                _buildTaxRow('TOTAL INCOME', 'USD ' + totalIncome.toStringAsFixed(0), success),
                                const SizedBox(height: 12),
                                _buildTaxRow('TOTAL EXPENSES', 'USD ' + totalExpenses.toStringAsFixed(0), orange),
                                const Divider(height: 24, color: Color(0xFF1C2E45)),
                                _buildTaxRow('NET PROFIT', 'USD ' + netProfit.toStringAsFixed(0), textPrimary, large: true),
                              ]),
                            ),

                            const SizedBox(height: 16),

                            if (categoryTotals.isNotEmpty) ...[
                              Align(alignment: Alignment.centerLeft, child: Text('EXPENSE BREAKDOWN', style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: textMuted))),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                                child: Column(
                                  children: categoryTotals.entries.map((entry) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: border, width: 0.5))),
                                      child: Row(children: [
                                        Icon(_categoryIcons[entry.key] ?? Icons.more_horiz, color: orange, size: 18),
                                        const SizedBox(width: 12),
                                        Expanded(child: Text(entry.key, style: GoogleFonts.barlow(fontSize: 14, color: textPrimary, fontWeight: FontWeight.w500))),
                                        Text('USD ' + entry.value.toStringAsFixed(0), style: GoogleFonts.barlowCondensed(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
                                      ]),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('MILEAGE SUMMARY', style: GoogleFonts.barlowCondensed(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2, color: textMuted)),
                                const SizedBox(height: 8),
                                Text(totalMiles.toString() + ' estimated miles', style: GoogleFonts.barlowCondensed(fontSize: 24, fontWeight: FontWeight.w900, color: textPrimary)),
                                const SizedBox(height: 4),
                                Text('IRS deduction: USD ' + mileageDeduction.toStringAsFixed(0), style: GoogleFonts.barlowCondensed(fontSize: 18, fontWeight: FontWeight.w800, color: success)),
                                const SizedBox(height: 4),
                                Text('Based on IRS standard mileage rate USD 0.70/mi', style: GoogleFonts.barlow(fontSize: 11, color: textMuted)),
                                Text('Estimated from ZIP codes logged — not actual odometer miles', style: GoogleFonts.barlow(fontSize: 10, color: textMuted)),
                              ]),
                            ),

                            const SizedBox(height: 20),

                            if (yearLoads.isEmpty && yearExpenses.isEmpty)
                              Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('No data for ' + _selectedYear.toString() + ' yet.', style: GoogleFonts.barlow(fontSize: 14, color: textMuted)))),

                            Row(children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isExporting ? null : () => _exportCSV(yearLoads, yearExpenses),
                                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF1C2E45)), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  child: _isExporting
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Color(0xFFF5921E), strokeWidth: 2))
                                      : Text('EXPORT CSV', style: GoogleFonts.barlowCondensed(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isExporting ? null : () => _exportPDF(yearLoads, yearExpenses, totalIncome, totalExpenses, totalMiles, driverName, mcNumber, categoryTotals),
                                  style: ElevatedButton.styleFrom(backgroundColor: orange, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  child: _isExporting
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : Text('TAX PDF', style: GoogleFonts.barlowCondensed(fontSize: 15, fontWeight: FontWeight.w800, color: background)),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 8),
                            Text('Consult a tax professional before filing. Mileage is estimated.', style: GoogleFonts.barlow(fontSize: 10, color: textMuted), textAlign: TextAlign.center),
                            const SizedBox(height: 24),
                          ]);
                        },
                      );
                    },
                  );
                },
              ),
          ]),
        ),
      ),
    );
  }

  Widget _buildTaxRow(String label, String value, Color color, {bool large = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.barlowCondensed(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1, color: textMuted)),
        Text(value, style: GoogleFonts.barlowCondensed(fontSize: large ? 28 : 20, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5)),
      ],
    );
  }
}
