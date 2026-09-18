import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/document_file.dart';
import '../models/document_type.dart';

/// Owns the app's on-device document library: a single root folder inside
/// the sandboxed app-documents directory, with a few well-known
/// sub-folders. Every screen that lists, opens, renames or deletes files
/// goes through this service so the "All Files" / "Created Files" counters
/// on Home stay consistent.
class FileRepositoryService {
  FileRepositoryService._();
  static final FileRepositoryService instance = FileRepositoryService._();

  static const String rootFolderName = 'AI PDF Scanner';

  Directory? _rootDir;

  Future<Directory> get rootDirectory async {
    if (_rootDir != null) return _rootDir!;
    final docs = await getApplicationDocumentsDirectory();
    final root = Directory(p.join(docs.path, rootFolderName));
    for (final sub in ['Scans', 'Converted', 'Imported', 'Merged']) {
      await Directory(p.join(root.path, sub)).create(recursive: true);
    }
    _rootDir = root;
    return root;
  }

  Future<Directory> subDirectory(String name) async {
    final root = await rootDirectory;
    final dir = Directory(p.join(root.path, name));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Signatures live in Application Support (not the visible documents
  /// root) since they are app data, not user-facing files.
  Future<Directory> get signaturesDirectory async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'signatures'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Lists every tracked document, newest first.
  Future<List<DocumentFile>> listAll({DocumentType? filterType}) async {
    final root = await rootDirectory;
    final files = <DocumentFile>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final ext = p.extension(entity.path).replaceAll('.', '').toLowerCase();
      if (ext.isEmpty) continue;
      final type = DocumentTypeX.fromExtension(ext);
      if (filterType != null && type != filterType) continue;
      final createdByApp = !p.dirname(entity.path).endsWith('Imported');
      files.add(DocumentFile.fromFile(entity, createdByApp: createdByApp));
    }
    files.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return files;
  }

  Future<int> countAll() async => (await listAll()).length;

  Future<int> countCreatedByApp() async =>
      (await listAll()).where((f) => f.createdByApp).length;

  Future<int> countByType(DocumentType type) async =>
      (await listAll(filterType: type)).length;

  Future<DocumentFile> importExternalFile(File source) async {
    final dest = await subDirectory('Imported');
    final target = await _uniquePath(dest.path, p.basename(source.path));
    final copied = await source.copy(target);
    return DocumentFile.fromFile(copied, createdByApp: false);
  }

  Future<DocumentFile> registerCreatedFile(File file, {String subFolder = 'Converted'}) async {
    return DocumentFile.fromFile(file, createdByApp: true);
  }

  Future<String> pathForNewFile({
    required String baseName,
    required String extension,
    String subFolder = 'Converted',
  }) async {
    final dest = await subDirectory(subFolder);
    return _uniquePath(dest.path, '$baseName.$extension');
  }

  Future<String> _uniquePath(String folder, String fileName) async {
    final ext = p.extension(fileName);
    final base = p.basenameWithoutExtension(fileName);
    var candidate = p.join(folder, fileName);
    var counter = 1;
    while (await File(candidate).exists()) {
      candidate = p.join(folder, '$base ($counter)$ext');
      counter++;
    }
    return candidate;
  }

  Future<DocumentFile> rename(DocumentFile file, String newBaseName) async {
    final ext = p.extension(file.path);
    final newPath = await _uniquePath(p.dirname(file.path), '$newBaseName$ext');
    final renamed = await File(file.path).rename(newPath);
    return DocumentFile.fromFile(renamed, createdByApp: file.createdByApp);
  }

  Future<void> delete(DocumentFile file) async {
    final f = File(file.path);
    if (await f.exists()) await f.delete();
  }

  Future<void> deleteMany(List<DocumentFile> files) async {
    for (final f in files) {
      await delete(f);
    }
  }
}
