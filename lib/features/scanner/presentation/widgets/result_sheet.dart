import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/scanner/domain/scan_result_model.dart';
import '../../../../features/history/providers/history_provider.dart';
import '../../../../features/settings/providers/settings_provider.dart';
import '../../../../shared/utils/scan_action_handler.dart';
import '../../../../shared/utils/clipboard_helper.dart';
import '../../../../shared/widgets/scan_type_badge.dart';
import '../../../../app/theme/app_text_styles.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Modal bottom sheet displaying scan result details with actions.
class ResultSheet extends ConsumerWidget {
  const ResultSheet({
    super.key,
    required this.result,
    required this.onScanNext,
    this.onScanFromGallery,
    this.readOnly = false,
  });

  final ScanResultModel result;

  /// Called when the user taps "Scan Next" — resumes the camera scanner.
  final VoidCallback onScanNext;

  /// If provided (gallery flow), shows a "Pick Another" button alongside
  /// "Scan Next", letting the user pick a new image without resuming camera.
  final VoidCallback? onScanFromGallery;

  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final wifiInfo =
        result.type == ScanType.wifi ? parseWifi(result.rawContent) : null;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    ScanTypeBadge(type: result.type),
                    const Spacer(),
                    Text(
                      timeago.format(result.scannedAt),
                      style: AppTextStyles.labelSmall
                          .copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Raw content
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(
                    result.rawContent,
                    style: AppTextStyles.mono.copyWith(color: cs.onSurface),
                    maxLines: 5,
                  ),
                ),

                // WiFi details
                if (wifiInfo != null) ...[
                  const SizedBox(height: 12),
                  _WifiDetails(wifi: wifiInfo, cs: cs),
                ],

                const SizedBox(height: 20),

                // Primary action(s)
                if (!readOnly) ...[
                  if (result.type == ScanType.url)
                    _UrlActionButtons(url: result.rawContent)
                  else
                    _PrimaryActionButton(result: result, wifiInfo: wifiInfo),
                  const SizedBox(height: 12),
                ],

                // Secondary actions (Copy, Share, Save, Generate)
                _SecondaryActionsRow(
                  result: result,
                  readOnly: readOnly,
                  onScanNext: onScanNext,
                ),

                const SizedBox(height: 20),

                // ── Scan Next / Pick Another ──────────────────────────────
                if (!readOnly)
                  _ScanNextBar(
                    onScanNext: onScanNext,
                    onScanFromGallery: onScanFromGallery,
                    cs: cs,
                  ),

                const SizedBox(height: 12),
              ],
            ),
          ),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scan Next bar
// ─────────────────────────────────────────────────────────────────────────────

class _ScanNextBar extends StatelessWidget {
  const _ScanNextBar({
    required this.onScanNext,
    required this.onScanFromGallery,
    required this.cs,
  });

  final VoidCallback onScanNext;
  final VoidCallback? onScanFromGallery;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final isGalleryFlow = onScanFromGallery != null;

    if (isGalleryFlow) {
      // Gallery flow: two buttons side by side
      return Row(
        children: [
          // Pick Another from Gallery
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onScanFromGallery,
              icon: const Icon(Icons.photo_library_rounded),
              label: const Text('Pick Another'),
            ),
          ),
          const SizedBox(width: 10),
          // Go to live camera
          Expanded(
            child: FilledButton.icon(
              onPressed: onScanNext,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Use Camera'),
            ),
          ),
        ],
      );
    }

    // Camera flow: single prominent "Scan Next" button
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onScanNext,
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text('Scan Next'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WiFi details
// ─────────────────────────────────────────────────────────────────────────────

class _WifiDetails extends StatelessWidget {
  const _WifiDetails({required this.wifi, required this.cs});
  final WifiCredentials wifi;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _InfoRow(label: 'Network', value: wifi.ssid, cs: cs),
          if (wifi.security.isNotEmpty) ...[
            const SizedBox(height: 6),
            _InfoRow(label: 'Security', value: wifi.security, cs: cs),
          ],
          if (wifi.password.isNotEmpty) ...[
            const SizedBox(height: 6),
            _InfoRow(label: 'Password', value: wifi.password, cs: cs),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, required this.cs});
  final String label;
  final String value;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style:
                AppTextStyles.labelSmall.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(color: cs.onSurface),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Primary action buttons
// ─────────────────────────────────────────────────────────────────────────────

/// Two side-by-side buttons shown only for URL scan type.
class _UrlActionButtons extends ConsumerWidget {
  const _UrlActionButtons({required this.url});
  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        // Open in Browser
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              final success = await handleScanAction(
                context,
                url,
                ScanType.url,
              );
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open link')),
                );
              }
            },
            icon: const Icon(Icons.open_in_browser_rounded),
            label: const Text('Open Link'),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Copy URL
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => ClipboardHelper.copy(url, label: 'URL copied'),
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy Link'),
          ),
        ),
      ],
    );
  }
}

class _PrimaryActionButton extends ConsumerWidget {
  const _PrimaryActionButton({required this.result, this.wifiInfo});
  final ScanResultModel result;
  final WifiCredentials? wifiInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          if (result.type == ScanType.wifi && wifiInfo != null) {
            await ClipboardHelper.copy(wifiInfo!.password,
                label: 'Password copied');
          } else if (result.type == ScanType.text) {
            await ClipboardHelper.copy(result.rawContent);
          } else {
            final success =
                await handleScanAction(context, result.rawContent, result.type);
            if (!success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not perform action')),
              );
            }
          }
        },
        icon: Icon(primaryActionIcon(result.type)),
        label: Text(primaryActionLabel(result.type)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Secondary actions row: Copy, Share, Save, Generate
// ─────────────────────────────────────────────────────────────────────────────

class _SecondaryActionsRow extends ConsumerWidget {
  const _SecondaryActionsRow({
    required this.result,
    required this.readOnly,
    required this.onScanNext,
  });
  final ScanResultModel result;
  final bool readOnly;
  final VoidCallback onScanNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final settings = ref.watch(appSettingsProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionChip(
          icon: Icons.copy_rounded,
          label: 'Copy',
          onTap: () => ClipboardHelper.copy(result.rawContent),
          cs: cs,
        ),
        _ActionChip(
          icon: Icons.share_rounded,
          label: 'Share',
          onTap: () => Share.share(result.rawContent),
          cs: cs,
        ),
        if (!readOnly && settings.saveHistory)
          _ActionChip(
            icon: Icons.history_rounded,
            label: 'Save',
            onTap: () async {
              await ref.read(historyProvider.notifier).addScan(result);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saved to history')),
                );
              }
            },
            cs: cs,
          ),
        _ActionChip(
          icon: Icons.qr_code_rounded,
          label: 'Generate',
          onTap: () {
            onScanNext(); // close sheet first
            context.go('/generator');
          },
          cs: cs,
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.cs,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: cs.primary),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style:
                AppTextStyles.labelSmall.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
