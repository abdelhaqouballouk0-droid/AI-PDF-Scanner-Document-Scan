import 'dart:io';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'file_repository_service.dart';

/// Wraps the native document scanner (Google ML Kit Document Scanner on
/// Android, VisionKit's VNDocumentCameraViewController on iOS). Both give
/// the user a full-screen camera with live edge detection, perspective
/// correction and multi-page capture out of the box — this service only
/// has to turn the resulting cropped page images into a PDF.
class DocumentScannerService {
  DocumentScannerService._();
  static final DocumentScannerService instance = DocumentScannerService._();

  /// Launches the native scanner UI and returns the cropped page image
  /// paths in capture order. Returns an empty list if the user cancels.
  Future<List<String>> scanPages({int maxPages = 40}) async {
    try {
      final paths = await CunningDocumentScanner.getPictures(
        noOfPages: maxPages,
        isGalleryImportAllowed: true,
      );
      return paths ?? [];
    } on PlatformException catch (_) {
      rethrow;
    }
  }

  /// Builds a single PDF file from a list of scanned/imported page images.
  ///
  /// [pageSize] should be one of `PdfPageFormat.a4`, `.letter`, or null to
  /// auto-fit each page to its source image's own aspect ratio.
  Future<File> buildPdfFromImages(
    List<String> imagePaths, {
    required String outputBaseName,
    PdfPageFormat? pageSize,
  }) async {
    final doc = pw.Document();

    for (final path in imagePaths) {
      final bytes = await File(path).readAsBytes();
      final image = pw.MemoryImage(bytes);

      doc.addPage(
        pw.Page(
          pageFormat: pageSize ?? PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (context) {
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );
    }

    final outPath = await FileRepositoryService.instance.pathForNewFile(
      baseName: outputBaseName,
      extension: 'pdf',
      subFolder: 'Scans',
    );
    final file = File(outPath);
    await file.writeAsBytes(await doc.save());
    return file;
  }
}
