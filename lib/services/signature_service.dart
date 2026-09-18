import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Rect;
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';
import '../models/signature_model.dart';
import 'file_repository_service.dart';
import 'storage_service.dart';

/// Manages saved signature images (drawn once with the `signature`
/// package's pad, reused afterwards) and stamps them onto real PDF pages
/// for the "Fill & Sign" tool.
class SignatureService {
  SignatureService._();
  static final SignatureService instance = SignatureService._();

  final _uuid = const Uuid();

  Future<List<SignatureModel>> getAll() => StorageService.instance.getSignatures();

  Future<SignatureModel> save({required String name, required Uint8List pngBytes}) async {
    final dir = await FileRepositoryService.instance.signaturesDirectory;
    final id = _uuid.v4();
    final path = p.join(dir.path, '$id.png');
    await File(path).writeAsBytes(pngBytes);

    final model = SignatureModel(
      id: id,
      name: name.trim().isEmpty ? 'Signature' : name.trim(),
      imagePath: path,
      createdAt: DateTime.now(),
    );

    final all = await getAll();
    all.insert(0, model);
    await StorageService.instance.saveSignatures(all);
    return model;
  }

  Future<void> rename(String id, String newName) async {
    final all = await getAll();
    final index = all.indexWhere((s) => s.id == id);
    if (index == -1) return;
    final updated = SignatureModel(
      id: all[index].id,
      name: newName,
      imagePath: all[index].imagePath,
      createdAt: all[index].createdAt,
    );
    all[index] = updated;
    await StorageService.instance.saveSignatures(all);
  }

  Future<void> delete(String id) async {
    final all = await getAll();
    final index = all.indexWhere((s) => s.id == id);
    if (index == -1) return;
    final file = File(all[index].imagePath);
    if (await file.exists()) await file.delete();
    all.removeAt(index);
    await StorageService.instance.saveSignatures(all);
  }

  /// Stamps [signaturePngBytes] onto one page of a PDF at a normalized
  /// position (0..1 fractions of the page width/height, top-left origin),
  /// with [widthFraction] controlling the signature's width relative to
  /// the page. Returns the resulting PDF bytes with the signature
  /// permanently flattened into the page content.
  Future<Uint8List> stampSignature({
    required Uint8List pdfBytes,
    required Uint8List signaturePngBytes,
    required int pageIndex,
    required double xFraction,
    required double yFraction,
    double widthFraction = 0.35,
  }) async {
    final document = PdfDocument(inputBytes: pdfBytes);
    final page = document.pages[pageIndex];
    final image = PdfBitmap(signaturePngBytes);

    final pageWidth = page.size.width;
    final pageHeight = page.size.height;

    final drawWidth = pageWidth * widthFraction;
    final aspect = image.height / image.width;
    final drawHeight = drawWidth * aspect;

    final x = pageWidth * xFraction;
    final y = pageHeight * yFraction;

    page.graphics.drawImage(image, Rect.fromLTWH(x, y, drawWidth, drawHeight));

    final bytes = await document.save();
    document.dispose();
    return Uint8List.fromList(bytes);
  }
}
