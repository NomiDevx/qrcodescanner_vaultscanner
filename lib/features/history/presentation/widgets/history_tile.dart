import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../scanner/domain/scan_result_model.dart';
import '../../providers/history_provider.dart';
import '../../../../shared/utils/scan_action_handler.dart';
import '../../../../shared/widgets/scan_type_badge.dart';
import '../../../../app/theme/app_text_styles.dart';

/// A dismissible tile for a scan result in the history list.
class HistoryTile extends ConsumerWidget {
  const HistoryTile({
    super.key,
    required this.result,
    required this.onTap,
  });

  final ScanResultModel result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey(result.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_rounded, color: cs.onErrorContainer),
      ),
      onDismissed: (_) {
        ref.read(historyProvider.notifier).deleteScan(result.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Scan deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                ref.read(historyProvider.notifier).addScan(result);
              },
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Type icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    scanTypeIcon(result.type),
                    size: 22,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.preview,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: cs.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ScanTypeBadge(type: result.type, compact: true),
                          const SizedBox(width: 8),
                          Text(
                            timeago.format(result.scannedAt),
                            style: AppTextStyles.labelSmall
                                .copyWith(color: cs.onSurfaceVariant),
                          ),
                          if (result.isFavorite) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.star_rounded,
                                size: 14, color: Colors.amber),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Chevron
                Icon(Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
