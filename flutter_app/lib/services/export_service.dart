// lib/services/export_service.dart
// Service d'export PDF et CSV pour les prix agricoles

import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class ExportService {
  /// Exporte les prix en PDF
  static Future<void> exportToPDF({
    required String title,
    required List<Map<String, dynamic>> data,
    required List<String> headers,
    String? filename,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('065F46'),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'AgriSmart',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        title,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 16,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Généré le: ${_formatDate(DateTime.now())}',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Table
                pw.Table.fromTextArray(
                  headers: headers,
                  data: data.map((row) {
                    return headers
                        .map((h) => row[h]?.toString() ?? '-')
                        .toList();
                  }).toList(),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('10B981'),
                  ),
                  cellHeight: 30,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.center,
                    2: pw.Alignment.center,
                    3: pw.Alignment.centerRight,
                  },
                ),

                pw.SizedBox(height: 20),

                // Footer
                pw.Text(
                  '© AgriSmart - Application de suivi des prix agricoles au Sénégal',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey,
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Sauvegarder et partager
      final bytes = await pdf.save();
      final outputFile = await _saveFile(
        bytes: bytes,
        filename: filename ?? 'agrismart_export_${_timestamp()}.pdf',
        mimeType: 'application/pdf',
      );

      await _shareFile(outputFile);
    } catch (e) {
      debugPrint('Erreur export PDF: $e');
      throw Exception('Impossible de générer le PDF: $e');
    }
  }

  /// Exporte les prix en CSV
  static Future<void> exportToCSV({
    required String title,
    required List<Map<String, dynamic>> data,
    required List<String> headers,
    String? filename,
  }) async {
    try {
      // Créer les lignes CSV
      List<List<dynamic>> rows = [headers];

      for (var row in data) {
        rows.add(headers.map((h) => row[h] ?? '-').toList());
      }

      // Convertir en CSV
      String csv = const ListToCsvConverter().convert(rows);

      // Sauvegarder et partager
      final bytes = utf8.encode(csv);
      final outputFile = await _saveFile(
        bytes: bytes,
        filename: filename ?? 'agrismart_export_${_timestamp()}.csv',
        mimeType: 'text/csv',
      );

      await _shareFile(outputFile);
    } catch (e) {
      debugPrint('Erreur export CSV: $e');
      throw Exception('Impossible de générer le CSV: $e');
    }
  }

  /// Exporte une comparaison de prix (pour le partage rapide)
  static Future<void> exportComparison({
    required String productName,
    required List<Map<String, dynamic>> marketPrices,
  }) async {
    final data = marketPrices
        .map((m) => {
              'Marché': m['market_name'],
              'Prix': '${m['price']} FCFA',
              'Date': _formatDate(DateTime.now()),
            })
        .toList();

    await exportToPDF(
      title: 'Comparaison des prix - $productName',
      data: data,
      headers: ['Marché', 'Prix', 'Date'],
      filename:
          'comparaison_${productName.toLowerCase().replaceAll(' ', '_')}.pdf',
    );
  }

  /// Partage simple via WhatsApp/SMS
  static Future<void> shareViaWhatsApp({
    required String productName,
    required List<Map<String, dynamic>> marketPrices,
  }) async {
    final StringBuffer text = StringBuffer();
    text.writeln('💰 *$productName* - Comparaison des prix:\n');

    // Trouver le meilleur prix
    var bestMarket = marketPrices
        .reduce((a, b) => (a['price'] ?? 0) > (b['price'] ?? 0) ? a : b);

    for (var market in marketPrices) {
      final isBest = market['market_name'] == bestMarket['market_name'];
      final emoji = isBest ? '✅' : '📍';
      final bestTag = isBest ? ' (MEILLEUR PRIX)' : '';
      text.writeln(
          '$emoji ${market['market_name']}: ${market['price']} FCFA$bestTag');
    }

    text.writeln('\nVia AgriSmart App 🌾');

    await Share.share(
      text.toString(),
      subject: 'Comparaison des prix - $productName',
    );
  }

  // Helper: Sauvegarder un fichier
  static Future<File> _saveFile({
    required List<int> bytes,
    required String filename,
    required String mimeType,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  // Helper: Partager un fichier
  static Future<void> _shareFile(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Export AgriSmart',
    );
  }

  // Helper: Format date
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Helper: Timestamp pour nom de fichier
  static String _timestamp() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  }
}
