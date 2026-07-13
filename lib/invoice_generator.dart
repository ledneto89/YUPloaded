import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class InvoiceGenerator {
  static Future<void> generateAndShare({
    required String loadNumber,
    required String driverName,
    required String mcNumber,
    required String pickupState,
    required String deliveryState,
    required double rate,
    required String brokerEmail,
    required BuildContext context,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('YUPLOADED',
                            style: pw.TextStyle(
                                fontSize: 32,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('F5921E'))),
                        pw.Text('Freight Invoice',
                            style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('INVOICE',
                            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                        pw.Text(loadNumber,
                            style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600)),
                        pw.Text(DateTime.now().toString().substring(0, 10),
                            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Divider(),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('FROM', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                        pw.SizedBox(height: 4),
                        pw.Text(driverName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.Text('MC: ' + mcNumber, style: const pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('BILL TO', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                        pw.SizedBox(height: 4),
                        pw.Text(brokerEmail, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('F5F5F5'),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('DESCRIPTION', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                          pw.SizedBox(height: 4),
                          pw.Text('Freight Transportation', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                          pw.Text(pickupState + ' to ' + deliveryState, style: const pw.TextStyle(fontSize: 12)),
                          pw.Text('Load: ' + loadNumber, style: const pw.TextStyle(fontSize: 12)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('AMOUNT', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                          pw.SizedBox(height: 4),
                          pw.Text('USD ' + rate.toStringAsFixed(2),
                              style: pw.TextStyle(
                                  fontSize: 24,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColor.fromHex('F5921E'))),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL DUE', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text('USD ' + rate.toStringAsFixed(2),
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('F5921E'))),
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Text('Payment Terms: Net 30',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                pw.SizedBox(height: 8),
                pw.Text('Please remit payment within 30 days of invoice date.',
                    style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
                pw.Spacer(),
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text('Generated by YUPLOADED - yuploaded.com',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey400)),
                ),
              ],
            );
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File(output.path + '/' + loadNumber + '_invoice.pdf');
      await file.writeAsBytes(await pdf.save());

      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Invoice ' + loadNumber + ' from YUPLOADED',
        text: 'Please find attached invoice ' + loadNumber + ' for freight transportation from ' + pickupState + ' to ' + deliveryState,
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : const Rect.fromLTWH(0, 0, 393, 852),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating invoice: ' + e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }
}

