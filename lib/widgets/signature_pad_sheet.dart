import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Shows a bottom sheet with a drawing pad and returns the signature as
/// transparent-background PNG bytes, or null if the user cancelled.
Future<Uint8List?> showSignaturePad(BuildContext context) {
  return showModalBottomSheet<Uint8List?>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const _SignaturePadSheet(),
  );
}

class _SignaturePadSheet extends StatefulWidget {
  const _SignaturePadSheet();

  @override
  State<_SignaturePadSheet> createState() => _SignaturePadSheetState();
}

class _SignaturePadSheetState extends State<_SignaturePadSheet> {
  late final SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.transparent,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_controller.isEmpty) {
      Navigator.pop(context);
      return;
    }
    final bytes = await _controller.toPngBytes();
    if (!mounted) return;
    Navigator.pop(context, bytes);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t('sigPadTitle'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              TextButton(
                onPressed: () => _controller.clear(),
                child: Text(t('sigPadClear')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 220,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Signature(
              controller: _controller,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t('commonCancel')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _confirm,
                  child: Text(t('fillSignConfirm')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
