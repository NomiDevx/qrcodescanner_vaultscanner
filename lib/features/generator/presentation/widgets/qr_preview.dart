import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/generator_provider.dart';

/// Live QR code preview widget.
class QrPreview extends ConsumerWidget {
  const QrPreview({super.key, this.repaintKey});

  final GlobalKey? repaintKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(generatorProvider);
    final cs = Theme.of(context).colorScheme;

    if (state.text.isEmpty) {
      return Container(
        width: state.size,
        height: state.size,
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_rounded,
                size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              'Enter text to generate\na QR code',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: state.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: QrImageView(
          data: state.text,
          version: QrVersions.auto,
          size: state.size,
          eyeStyle: QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: state.foregroundColor,
          ),
          dataModuleStyle: QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: state.foregroundColor,
          ),
          errorCorrectionLevel: state.errorCorrectionLevel,
          backgroundColor: state.backgroundColor,
        ),
      ),
    );
  }
}
