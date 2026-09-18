import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Offset, Size;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart' as pdfw;
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'file_repository_service.dart';

/// A single page taken from a source PDF, optionally with extra rotation
/// applied on top of whatever rotation it already has. This is the one
/// primitive every page-level tool (reorder, delete, extract, split,
/// merge, rotate) is built from: point at a page, get a new document back.
class PdfPageRef {
  final Uint8List sourceBytes;
  final int pageIndex;
  final int extraRotationDegrees;

  const PdfPageRef({
    required this.sourceBytes,
    required this.pageIndex,
    this.extraRotationDegrees = 0,
  });
}

/// Thickness of the JPEG re-encode used by [compress]. Higher = smaller
/// file, lower visual fidelity.
enum CompressionLevel { low, medium, high }

/// Real, on-device PDF manipulation built on `syncfusion_flutter_pdf`
/// (structural edits: merge/split/reorder/rotate/delete/extract, password
/// protect/unlock, text extraction) plus `printing` (PDFium page
/// rasterization, used for thumbnails and for the "compress" tool).
class PdfToolsService {
  PdfToolsService._();
  static final PdfToolsService instance = PdfToolsService._();

  // ---- Inspection -------------------------------------------------------

  Future<int> getPageCount(Uint8List bytes) async {
    final doc = PdfDocument(inputBytes: bytes);
    final count = doc.pages.count;
    doc.dispose();
    return count;
  }

  Future<String> extractText(Uint8List bytes, {int? startPage, int? endPage}) async {
    final doc = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(doc);
    final text = extractor.extractText(
      startPageIndex: startPage,
      endPageIndex: endPage,
    );
    doc.dispose();
    return text;
  }

  /// Renders a single page as a PNG thumbnail/preview using PDFium.
  Future<Uint8List> renderPageImage(
    Uint8List bytes,
    int pageIndex, {
    double dpi = 90,
  }) async {
    await for (final page in Printing.raster(bytes, pages: [pageIndex], dpi: dpi)) {
      return page.toPng();
    }
    throw StateError('Could not render page $pageIndex');
  }

  // ---- Generic page rebuild (reorder / delete / extract / split / merge / rotate) ---

  /// Builds a brand new PDF document out of an ordered list of page
  /// references, each of which may come from a different source file.
  /// This single primitive powers every "Organize pages" action.
  Future<Uint8List> buildFromPages(List<PdfPageRef> refs) async {
    if (refs.isEmpty) {
      throw ArgumentError('Cannot build a PDF with zero pages');
    }

    final openDocs = <Uint8List, PdfDocument>{};
    PdfDocument openFor(Uint8List bytes) =>
        openDocs.putIfAbsent(bytes, () => PdfDocument(inputBytes: bytes));

    final newDoc = PdfDocument();
    newDoc.pageSettings.margins.all = 0;

    for (final ref in refs) {
      final source = openFor(ref.sourceBytes);
      final sourcePage = source.pages[ref.pageIndex];
      final template = sourcePage.createTemplate();

      newDoc.pageSettings.size =
          Size(sourcePage.size.width, sourcePage.size.height);
      final newPage = newDoc.pages.add();
      newPage.graphics.drawPdfTemplate(template, const Offset(0, 0));

      if (ref.extraRotationDegrees != 0) {
        newPage.rotation = _rotationFromDegrees(
          (_currentRotationDegrees(sourcePage) + ref.extraRotationDegrees) % 360,
        );
      } else {
        newPage.rotation = sourcePage.rotation;
      }
    }

    final bytes = await newDoc.save();
    newDoc.dispose();
    for (final d in openDocs.values) {
      d.dispose();
    }
    return Uint8List.fromList(bytes);
  }

  int _currentRotationDegrees(PdfPage page) {
    switch (page.rotation) {
      case PdfPageRotateAngle.rotateAngle90:
        return 90;
      case PdfPageRotateAngle.rotateAngle180:
        return 180;
      case PdfPageRotateAngle.rotateAngle270:
        return 270;
      case PdfPageRotateAngle.rotateAngle0:
        return 0;
    }
  }

  PdfPageRotateAngle _rotationFromDegrees(int degrees) {
    switch (degrees) {
      case 90:
        return PdfPageRotateAngle.rotateAngle90;
      case 180:
        return PdfPageRotateAngle.rotateAngle180;
      case 270:
        return PdfPageRotateAngle.rotateAngle270;
      default:
        return PdfPageRotateAngle.rotateAngle0;
    }
  }

  /// Convenience: build [PdfPageRef]s for every page of a single document,
  /// in order — used by "Merge PDF" (each file contributes all its pages).
  Future<List<PdfPageRef>> allPageRefs(Uint8List bytes) async {
    final count = await getPageCount(bytes);
    return List.generate(count, (i) => PdfPageRef(sourceBytes: bytes, pageIndex: i));
  }

  /// Merges several whole PDFs, in the given order, into one file.
  Future<Uint8List> mergeDocuments(List<Uint8List> documents) async {
    final refs = <PdfPageRef>[];
    for (final bytes in documents) {
      refs.addAll(await allPageRefs(bytes));
    }
    return buildFromPages(refs);
  }

  /// Splits a document into one file per contiguous page range.
  /// `ranges` are inclusive, 0-based, e.g. `[(0,2), (3,5)]`.
  Future<List<Uint8List>> splitDocument(
    Uint8List bytes,
    List<({int start, int end})> ranges,
  ) async {
    final results = <Uint8List>[];
    for (final range in ranges) {
      final refs = [
        for (var i = range.start; i <= range.end; i++)
          PdfPageRef(sourceBytes: bytes, pageIndex: i),
      ];
      results.add(await buildFromPages(refs));
    }
    return results;
  }

  // ---- Security -----------------------------------------------------------

  Future<Uint8List> protect(
    Uint8List bytes, {
    required String password,
    String? ownerPassword,
  }) async {
    final doc = PdfDocument(inputBytes: bytes);
    doc.security.userPassword = password;
    doc.security.ownerPassword = ownerPassword ?? password;
    doc.security.algorithm = PdfEncryptionAlgorithm.aesx256Bit;
    final out = await doc.save();
    doc.dispose();
    return Uint8List.fromList(out);
  }

  Future<Uint8List> unlock(Uint8List bytes, {required String password}) async {
    final doc = PdfDocument(inputBytes: bytes, password: password);
    doc.security.userPassword = '';
    doc.security.ownerPassword = '';
    final out = await doc.save();
    doc.dispose();
    return Uint8List.fromList(out);
  }

  /// Returns true if the document requires a password to open.
  bool isEncrypted(Uint8List bytes) {
    try {
      final doc = PdfDocument(inputBytes: bytes);
      doc.dispose();
      return false;
    } catch (_) {
      return true;
    }
  }

  // ---- Compression --------------------------------------------------------

  /// Re-rasterizes every page to a JPEG at a reduced DPI/quality and
  /// rebuilds the PDF from those images. This is the same approach most
  /// mobile "compress PDF" tools use for scan-heavy documents; it is very
  /// effective on image-based PDFs (like ones produced by the scanner) and
  /// less effective on already-vector/text PDFs, which it will also
  /// rasterize (trading searchable text for a smaller file).
  Future<Uint8List> compress(Uint8List bytes, CompressionLevel level) async {
    final (dpi, quality) = switch (level) {
      CompressionLevel.low => (150.0, 85),
      CompressionLevel.medium => (110.0, 70),
      CompressionLevel.high => (80.0, 45),
    };

    final pdfDoc = pw.Document();
    await for (final page in Printing.raster(bytes, dpi: dpi)) {
      final png = await page.toPng();
      final decoded = img.decodePng(png);
      final jpgBytes = decoded == null
          ? png
          : Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
      final image = pw.MemoryImage(jpgBytes);

      final widthPoints = page.width / dpi * pdfw.PdfPageFormat.inch;
      final heightPoints = page.height / dpi * pdfw.PdfPageFormat.inch;

      pdfDoc.addPage(
        pw.Page(
          pageFormat: pdfw.PdfPageFormat(widthPoints, heightPoints),
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Image(image, fit: pw.BoxFit.contain),
        ),
      );
    }
    return pdfDoc.save();
  }

  // ---- Persistence helper --------------------------------------------------

  Future<File> saveBytesAsNewFile(
    Uint8List bytes, {
    required String baseName,
    String subFolder = 'Converted',
  }) async {
    final path = await FileRepositoryService.instance.pathForNewFile(
      baseName: baseName,
      extension: 'pdf',
      subFolder: subFolder,
    );
    final file = File(path);
    await file.writeAsBytes(bytes);
    return file;
  }
}
