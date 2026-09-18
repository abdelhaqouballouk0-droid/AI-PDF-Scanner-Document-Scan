import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/signature_model.dart';
import '../services/signature_service.dart';

class SignatureNotifier extends StateNotifier<AsyncValue<List<SignatureModel>>> {
  SignatureNotifier() : super(const AsyncValue.loading()) {
    refresh();
  }

  final _service = SignatureService.instance;

  Future<void> refresh() async {
    try {
      final list = await _service.getAll();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> add(String name, Uint8List pngBytes) async {
    await _service.save(name: name, pngBytes: pngBytes);
    await refresh();
  }

  Future<void> rename(String id, String newName) async {
    await _service.rename(id, newName);
    await refresh();
  }

  Future<void> delete(String id) async {
    await _service.delete(id);
    await refresh();
  }
}

final signatureProvider =
    StateNotifierProvider<SignatureNotifier, AsyncValue<List<SignatureModel>>>(
  (ref) => SignatureNotifier(),
);
