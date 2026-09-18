import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'file_repository_service.dart';
import 'pdf_tools_service.dart';
import 'storage_service.dart';

/// The conversions the "Convert" tool understands. Image<->PDF and
/// PDF->JPG are done fully on-device. Office formats (Word/Excel) cannot
/// be rendered faithfully without a real layout engine, so those two
/// routes are implemented against a pluggable HTTP conversion backend —
/// see [ConversionService.officeConversionContract] for the tiny REST
/// contract it expects (a self-hosted Gotenberg/LibreOffice service, or a
/// hosted API such as CloudConvert/ConvertAPI, both work).
enum ConversionKind {
  imageToPdf,
  pdfToImage,
  wordToPdf,
  excelToPdf,
  pdfToWord,
  pdfToExcel,
}

extension ConversionKindX on ConversionKind {
  bool get isOnDevice =>
      this == ConversionKind.imageToPdf || this == ConversionKind.pdfToImage;

  String get title {
    switch (this) {
      case ConversionKind.imageToPdf:
        return 'Image en PDF';
      case ConversionKind.pdfToImage:
        return 'PDF en JPG';
      case ConversionKind.wordToPdf:
        return 'Word en PDF';
      case ConversionKind.excelToPdf:
        return 'Excel en PDF';
      case ConversionKind.pdfToWord:
        return 'PDF en Word';
      case ConversionKind.pdfToExcel:
        return 'PDF en Excel';
    }
  }
}

class ConversionResult {
  final List<File> files;
  const ConversionResult(this.files);
}

/// Thrown when an office-format conversion is requested but no backend
/// URL has been configured in Settings.
class ConversionBackendNotConfigured implements Exception {
  final String message;
  ConversionBackendNotConfigured([
    this.message =
        'Aucun serveur de conversion configuré. Ouvre Réglages > Conversion pour renseigner une URL.',
  ]);
  @override
  String toString() => message;
}

class ConversionService {
  ConversionService._();
  static final ConversionService instance = ConversionService._();

  /// Contract expected from the optional office-conversion backend:
  /// `POST {baseUrl}/convert?to=pdf|docx|xlsx`
  /// multipart/form-data, field name "file" = the source file.
  /// Response: 200 with the converted file's raw bytes in the body.
  static const String officeConversionContract =
      'POST {baseUrl}/convert?to=<pdf|docx|xlsx>  (multipart field "file") -> raw file bytes';

  // ---- On-device: Image(s) -> PDF ---------------------------------------

  Future<File> imagesToPdf(List<File> images, {String baseName = 'Document'}) async {
    final doc = pw.Document();
    for (final image in images) {
      final bytes = await image.readAsBytes();
      final memImage = pw.MemoryImage(bytes);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Center(child: pw.Image(memImage, fit: pw.BoxFit.contain)),
        ),
      );
    }
    final outPath = await FileRepositoryService.instance.pathForNewFile(
      baseName: baseName,
      extension: 'pdf',
      subFolder: 'Converted',
    );
    final file = File(outPath);
    await file.writeAsBytes(await doc.save());
    return file;
  }

  // ---- On-device: PDF -> JPG (one image per page) ------------------------

  Future<List<File>> pdfToImages(File pdfFile, {double dpi = 150}) async {
    final bytes = await pdfFile.readAsBytes();
    final pageCount = await PdfToolsService.instance.getPageCount(bytes);
    final baseName = p.basenameWithoutExtension(pdfFile.path);
    final results = <File>[];

    for (var i = 0; i < pageCount; i++) {
      final png = await PdfToolsService.instance.renderPageImage(bytes, i, dpi: dpi);
      final outPath = await FileRepositoryService.instance.pathForNewFile(
        baseName: '$baseName-page${i + 1}',
        extension: 'jpg',
        subFolder: 'Converted',
      );
      final file = File(outPath);
      await file.writeAsBytes(png);
      results.add(file);
    }
    return results;
  }

  // ---- Pluggable backend: Office <-> PDF ---------------------------------

  Future<File> convertViaBackend(
    File input, {
    required String targetExtension,
  }) async {
    final baseUrl = await StorageService.instance.getOfficeConversionUrl();
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      throw ConversionBackendNotConfigured();
    }

    final uri = Uri.parse('$baseUrl/convert?to=$targetExtension');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', input.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception(
        'Le serveur de conversion a répondu ${response.statusCode}: ${response.reasonPhrase}',
      );
    }

    final baseName = p.basenameWithoutExtension(input.path);
    final outPath = await FileRepositoryService.instance.pathForNewFile(
      baseName: baseName,
      extension: targetExtension,
      subFolder: 'Converted',
    );
    final outFile = File(outPath);
    await outFile.writeAsBytes(response.bodyBytes);
    return outFile;
  }

  Future<File> wordToPdf(File docxFile) => convertViaBackend(docxFile, targetExtension: 'pdf');
  Future<File> excelToPdf(File xlsxFile) => convertViaBackend(xlsxFile, targetExtension: 'pdf');
  Future<File> pdfToWord(File pdfFile) => convertViaBackend(pdfFile, targetExtension: 'docx');
  Future<File> pdfToExcel(File pdfFile) => convertViaBackend(pdfFile, targetExtension: 'xlsx');
}
