import 'package:flutter/material.dart';
import '../../features/scanner/domain/scan_result_model.dart';
import '../../shared/utils/scan_action_handler.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

/// A small colored chip badge showing the scan type label.
class ScanTypeBadge extends StatelessWidget {
  const ScanTypeBadge({
    super.key,
    required this.type,
    this.compact = false,
  });

  final ScanType type;
  final bool compact;

  Color _badgeColor() {
    switch (type) {
      case ScanType.url:
        return AppColors.urlColor;
      case ScanType.phone:
        return AppColors.phoneColor;
      case ScanType.email:
        return AppColors.emailColor;
      case ScanType.wifi:
        return AppColors.wifiColor;
      case ScanType.vcard:
        return AppColors.vcardColor;
      case ScanType.geo:
        return AppColors.geoColor;
      case ScanType.sms:
        return AppColors.smsColor;
      case ScanType.text:
        return AppColors.textColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _badgeColor();
    final label = scanTypeLabel(type);
    final icon = scanTypeIcon(type);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: color),
          SizedBox(width: compact ? 4 : 6),
          Text(
            label,
            style: (compact ? AppTextStyles.labelSmall : AppTextStyles.labelMedium)
                .copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
