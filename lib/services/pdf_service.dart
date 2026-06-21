import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/scanned_document.dart';

/// Service for PDF generation operations
class PDFService {
  final _uuid = const Uuid();

  /// Generate PDF from a scanned document
  Future<File> generatePDF(ScannedDocument document) async {
    final pdf = pw.Document();

    // Add pages to PDF
    for (final page in document.pages) {
      final imageFile = page.processedImage ?? page.originalImage;
      final imageBytes = await imageFile.readAsBytes();
      final pdfImage = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(
                pdfImage,
                fit: pw.BoxFit.contain,
              ),
            );
          },
        ),
      );
    }

    // Save PDF to file
    final outputDir = await getApplicationDocumentsDirectory();
    final outputPath = '${outputDir.path}/${document.title}_${_uuid.v4()}.pdf';
    final pdfFile = File(outputPath);
    await pdfFile.writeAsBytes(await pdf.save());

    return pdfFile;
  }

  /// Generate PDF with OCR text overlay (searchable PDF)
  Future<File> generateSearchablePDF(ScannedDocument document) async {
    final pdf = pw.Document();

    for (final page in document.pages) {
      final imageFile = page.processedImage ?? page.originalImage;
      final imageBytes = await imageFile.readAsBytes();
      final pdfImage = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                // Background image
                pw.Positioned(
                  left: 0,
                  top: 0,
                  child: pw.Image(
                    pdfImage,
                    width: PdfPageFormat.a4.width,
                    height: PdfPageFormat.a4.height,
                    fit: pw.BoxFit.contain,
                  ),
                ),
                // Hidden text layer for searchability (if OCR text exists)
                if (page.hasOCRText)
                  pw.Positioned(
                    left: 50,
                    top: 50,
                    child: pw.Text(
                      page.ocrText ?? '',
                      style: pw.TextStyle(
                        color: PdfColors.transparent,
                        fontSize: 1,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }

    // Save PDF to file
    final outputDir = await getApplicationDocumentsDirectory();
    final outputPath = '${outputDir.path}/${document.title}_searchable_${_uuid.v4()}.pdf';
    final pdfFile = File(outputPath);
    await pdfFile.writeAsBytes(await pdf.save());

    return pdfFile;
  }

  /// Merge multiple documents into a single PDF
  Future<File> mergeDocuments(List<ScannedDocument> documents, String outputName) async {
    final pdf = pw.Document();

    for (final document in documents) {
      for (final page in document.pages) {
        final imageFile = page.processedImage ?? page.originalImage;
        final imageBytes = await imageFile.readAsBytes();
        final pdfImage = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(
                  pdfImage,
                  fit: pw.BoxFit.contain,
                ),
              );
            },
          ),
        );
      }
    }

    // Save PDF to file
    final outputDir = await getApplicationDocumentsDirectory();
    final outputPath = '${outputDir.path}/${outputName}_${_uuid.v4()}.pdf';
    final pdfFile = File(outputPath);
    await pdfFile.writeAsBytes(await pdf.save());

    return pdfFile;
  }
}
