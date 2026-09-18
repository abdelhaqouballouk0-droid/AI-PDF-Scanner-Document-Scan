import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as p;
import 'pdf_tools_service.dart';
import 'file_repository_service.dart';

/// Real, on-device OCR (no network call, no per-page cost) powered by
/// Google ML Kit's text recognizer — this is what the "Image to Text"
/// tool in the More Tools grid runs.
class OcrService {
  OcrService._();
  static final OcrService instance = OcrService._();

  final TextRecognizer _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> recognizeImage(File imageFile) async {
    final input = InputImage.fromFile(imageFile);
    final result = await _recognizer.processImage(input);
    return result.text;
  }

  /// Runs OCR page-by-page on a PDF by rasterizing each page first, then
  /// feeding the raster to ML Kit. Useful for scanned PDFs that have no
  /// embedded text layer.
  Future<String> recognizePdf(File pdfFile, {double dpi = 200}) async {
    final bytes = await pdfFile.readAsBytes();
    final pageCount = await PdfToolsService.instance.getPageCount(bytes);
    final buffer = StringBuffer();

    for (var i = 0; i < pageCount; i++) {
      final png = await PdfToolsService.instance.renderPageImage(bytes, i, dpi: dpi);
      final tmpPath = await FileRepositoryService.instance.pathForNewFile(
        baseName: '${p.basenameWithoutExtension(pdfFile.path)}-ocr-page${i + 1}',
        extension: 'png',
        subFolder: 'Converted',
      );
      final tmpFile = File(tmpPath);
      await tmpFile.writeAsBytes(png);
      final text = await recognizeImage(tmpFile);
      buffer.writeln(text);
      await tmpFile.delete();
    }
    return buffer.toString().trim();
  }

  Future<void> dispose() async {
    await _recognizer.close();
  }
}
