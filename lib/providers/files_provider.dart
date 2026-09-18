import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/document_file.dart';
import '../models/document_type.dart';
import '../services/file_repository_service.dart';

/// Holds the full document library and exposes a few derived views
/// (by type, counts) so Home/Files/Tools screens all read from one place
/// and stay in sync after a scan, import, conversion or delete.
class FilesNotifier extends StateNotifier<AsyncValue<List<DocumentFile>>> {
  FilesNotifier() : super(const AsyncValue.loading()) {
    refresh();
  }

  final _repo = FileRepositoryService.instance;

  Future<void> refresh() async {
    try {
      final files = await _repo.listAll();
      state = AsyncValue.data(files);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> delete(DocumentFile file) async {
    await _repo.delete(file);
    await refresh();
  }

  Future<void> deleteMany(List<DocumentFile> files) async {
    await _repo.deleteMany(files);
    await refresh();
  }

  Future<DocumentFile> rename(DocumentFile file, String newBaseName) async {
    final renamed = await _repo.rename(file, newBaseName);
    await refresh();
    return renamed;
  }

  Future<DocumentFile> importFile(String path) async {
    final imported = await _repo.importExternalFile(File(path));
    await refresh();
    return imported;
  }
}

final filesProvider =
    StateNotifierProvider<FilesNotifier, AsyncValue<List<DocumentFile>>>(
  (ref) => FilesNotifier(),
);

/// Files filtered to a single [DocumentType], or all files when null.
final filteredFilesProvider =
    Provider.family<List<DocumentFile>, DocumentType?>((ref, type) {
  final files = ref.watch(filesProvider).valueOrNull ?? const [];
  if (type == null) return files;
  return files.where((f) => f.type == type).toList();
});

class LibraryCounts {
  final int all;
  final int createdByApp;
  final Map<DocumentType, int> byType;
  const LibraryCounts({required this.all, required this.createdByApp, required this.byType});
}

final libraryCountsProvider = Provider<LibraryCounts>((ref) {
  final files = ref.watch(filesProvider).valueOrNull ?? const [];
  final byType = <DocumentType, int>{};
  for (final type in DocumentType.values) {
    byType[type] = files.where((f) => f.type == type).length;
  }
  return LibraryCounts(
    all: files.length,
    createdByApp: files.where((f) => f.createdByApp).length,
    byType: byType,
  );
});
