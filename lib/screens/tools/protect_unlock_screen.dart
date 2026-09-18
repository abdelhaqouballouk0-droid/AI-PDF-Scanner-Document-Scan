import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/document_file.dart';
import '../../providers/files_provider.dart';
import '../../services/pdf_tools_service.dart';
import '../../widgets/common_widgets.dart';
import '../viewer/pdf_viewer_screen.dart';

enum ProtectMode { protect, unlock }

class ProtectUnlockScreen extends ConsumerStatefulWidget {
  final DocumentFile document;
  final ProtectMode mode;

  const ProtectUnlockScreen({super.key, required this.document, required this.mode});

  @override
  ConsumerState<ProtectUnlockScreen> createState() => _ProtectUnlockScreenState();
}

class _ProtectUnlockScreenState extends ConsumerState<ProtectUnlockScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _working = false;
  bool _obscure = true;

  bool get _isProtect => widget.mode == ProtectMode.protect;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    if (password.isEmpty) return;
    if (_isProtect && password != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les mots de passe ne correspondent pas')),
      );
      return;
    }

    setState(() => _working = true);
    try {
      final bytes = await widget.document.file.readAsBytes();
      final result = _isProtect
          ? await PdfToolsService.instance.protect(bytes, password: password)
          : await PdfToolsService.instance.unlock(bytes, password: password);

      final suffix = _isProtect ? 'protege' : 'deverrouille';
      final baseName = '${_stripExtension(widget.document.name)}-$suffix';
      final file = await PdfToolsService.instance.saveBytesAsNewFile(result, baseName: baseName);
      await ref.read(filesProvider.notifier).refresh();
      if (!mounted) return;

      final doc = DocumentFile.fromFile(file, createdByApp: true);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PdfViewerScreen(document: doc)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isProtect ? 'Erreur : $e' : 'Mot de passe incorrect ou fichier invalide')),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  String _stripExtension(String name) => name.replaceAll(RegExp(r'\.[^.]+$'), '');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isProtect ? 'Protéger le PDF' : 'Déverrouiller le PDF')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.document.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: _isProtect ? 'Nouveau mot de passe' : 'Mot de passe actuel',
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            if (_isProtect) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _confirmController,
                obscureText: _obscure,
                decoration: const InputDecoration(labelText: 'Confirmer le mot de passe'),
              ),
            ],
            const SizedBox(height: 24),
            LoadingButton(
              label: _isProtect ? 'Protéger' : 'Déverrouiller',
              icon: _isProtect ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
              loading: _working,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
