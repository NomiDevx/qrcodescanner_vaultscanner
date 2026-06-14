import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../providers/generator_provider.dart';
import '../../../../shared/utils/clipboard_helper.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import 'widgets/qr_preview.dart';

class GeneratorScreen extends ConsumerStatefulWidget {
  const GeneratorScreen({super.key});

  @override
  ConsumerState<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends ConsumerState<GeneratorScreen> {
  final _textController = TextEditingController();
  final _repaintKey = GlobalKey();
  bool _isSaving = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<Uint8List?> _captureQr() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveToGallery() async {
    if (_isSaving) return;
    final state = ref.read(generatorProvider);
    if (state.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter text first to generate a QR code')),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Check gallery access
    final hasAccess = await Gal.hasAccess();
    if (!hasAccess) {
      await Gal.requestAccess();
      if (!await Gal.hasAccess()) {
        setState(() => _isSaving = false);
        return;
      }
    }

    final bytes = await _captureQr();
    if (bytes == null) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture QR code')),
        );
      }
      return;
    }

    try {
      await Gal.putImageBytes(bytes,
          name: 'scanvault_qr_${DateTime.now().millisecondsSinceEpoch}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR code saved to gallery')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save QR code')),
        );
      }
    }

    setState(() => _isSaving = false);
  }


  Future<void> _shareQr() async {
    final state = ref.read(generatorProvider);
    if (state.text.isEmpty) return;

    final bytes = await _captureQr();
    if (bytes == null) return;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/scanvault_qr.png');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      text: 'Scan this QR code: ${state.text}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(generatorProvider);
    final notifier = ref.read(generatorProvider.notifier);

    final colorOptions = [
      Colors.black,
      AppColors.brandTeal,
      const Color(0xFF1A237E), // Navy
      const Color(0xFFC62828), // Red
      const Color(0xFF6A1B9A), // Purple
    ];

    final ecLevels = [
      (QrErrorCorrectLevel.L, 'L — Low (7%)'),
      (QrErrorCorrectLevel.M, 'M — Medium (15%)'),
      (QrErrorCorrectLevel.Q, 'Q — Quarter (25%)'),
      (QrErrorCorrectLevel.H, 'H — High (30%)'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Generator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QR Preview — centered
            Center(
              child: QrPreview(repaintKey: _repaintKey),
            ),

            const SizedBox(height: 28),

            // Action buttons
            if (state.text.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSaving ? null : _saveToGallery,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_rounded),
                      label: Text(_isSaving ? 'Saving...' : 'Save'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _shareQr,
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Share'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          ClipboardHelper.copy(state.text, label: 'Text copied'),
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Text input
            const _SectionLabel('Content'),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              onChanged: notifier.setText,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter URL, text, phone number...',
              ),
            ),

            const SizedBox(height: 24),

            // Size slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionLabel('Size'),
                Text(
                  '${state.size.round()}px',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
            Slider(
              value: state.size,
              min: 100,
              max: 400,
              divisions: 30,
              label: '${state.size.round()}px',
              onChanged: notifier.setSize,
            ),

            const SizedBox(height: 20),

            // Foreground color
            const _SectionLabel('Color'),
            const SizedBox(height: 10),
            Row(
              children: colorOptions
                  .map(
                    (color) => GestureDetector(
                      onTap: () => notifier.setForegroundColor(color),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: state.foregroundColor == color
                                ? cs.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: state.foregroundColor == color
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  )
                                ]
                              : [],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 20),

            // Background color
            const _SectionLabel('Background'),
            const SizedBox(height: 10),
            Row(
              children: [
                _BgColorOption(
                  color: Colors.white,
                  label: 'White',
                  isSelected: state.backgroundColor == Colors.white,
                  onTap: () => notifier.setBackgroundColor(Colors.white),
                  cs: cs,
                ),
                const SizedBox(width: 10),
                _BgColorOption(
                  color: Colors.transparent,
                  label: 'Clear',
                  isSelected: state.backgroundColor == Colors.transparent,
                  onTap: () =>
                      notifier.setBackgroundColor(Colors.transparent),
                  cs: cs,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Error correction
            const _SectionLabel('Error Correction'),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: state.errorCorrectionLevel,
              decoration: const InputDecoration(),
              items: ecLevels
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.$1,
                      child: Text(e.$2,
                          style: AppTextStyles.bodyMedium),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) notifier.setErrorCorrection(v);
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.labelLarge.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _BgColorOption extends StatelessWidget {
  const _BgColorOption({
    required this.color,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.cs,
  });
  final Color color;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color == Colors.transparent ? null : color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          gradient: color == Colors.transparent
              ? LinearGradient(colors: [
                  cs.surfaceContainer,
                  cs.surfaceContainer,
                ])
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: color == Colors.white ? Colors.black87 : cs.onSurface,
          ),
        ),
      ),
    );
  }
}
