import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:scanvault/features/history/providers/history_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/settings_provider.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final settings = ref.watch(appSettingsProvider);
    final themeModeNotifier = ref.read(themeModeProvider.notifier);
    final settingsNotifier = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ── Appearance ──────────────────────────────────────────────────
          _SectionHeader('Appearance'),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: cs.onSurface)),
                  const SizedBox(height: 10),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_rounded),
                        label: Text('System'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_rounded),
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_rounded),
                        label: Text('Dark'),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (s) =>
                        themeModeNotifier.setMode(s.first),
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: cs.primaryContainer,
                      selectedForegroundColor: cs.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                _SwitchTile(
                  icon: Icons.vibration_rounded,
                  title: 'Vibration on scan',
                  subtitle: 'Vibrate when a code is detected',
                  value: settings.vibrationEnabled,
                  onChanged: settingsNotifier.setVibration,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Scanner ──────────────────────────────────────────────────────
          _SectionHeader('Scanner'),

          Card(
            child: Column(
              children: [
                _SwitchTile(
                  icon: Icons.open_in_browser_rounded,
                  title: 'Auto-open URLs',
                  subtitle: 'Automatically open URLs in browser',
                  value: settings.autoOpenUrl,
                  onChanged: settingsNotifier.setAutoOpenUrl,
                ),
                Divider(
                    height: 1,
                    indent: 56,
                    endIndent: 16,
                    color: cs.outlineVariant),
                _SwitchTile(
                  icon: Icons.history_rounded,
                  title: 'Save to history',
                  subtitle: 'Store scans in local history',
                  value: settings.saveHistory,
                  onChanged: settingsNotifier.setSaveHistory,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── History ──────────────────────────────────────────────────────
          _SectionHeader('History'),

          Card(
            child: Column(
              children: [
                _TappableTile(
                  icon: Icons.delete_forever_rounded,
                  iconColor: cs.error,
                  title: 'Clear all history',
                  subtitle: 'Permanently delete all saved scans',
                  onTap: () => _confirmClearHistory(context, ref),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── About ────────────────────────────────────────────────────────
          _SectionHeader('About'),

          Card(
            child: Column(
              children: [
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (ctx, snap) {
                    final version = snap.data != null
                        ? '${snap.data!.version}+${snap.data!.buildNumber}'
                        : '—';
                    return _InfoTile(
                      icon: Icons.info_outline_rounded,
                      title: 'Version',
                      trailing: version,
                    );
                  },
                ),
                Divider(
                    height: 1,
                    indent: 56,
                    endIndent: 16,
                    color: cs.outlineVariant),
                _TappableTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () => _openPrivacyPolicy(context),
                ),
                Divider(
                    height: 1,
                    indent: 56,
                    endIndent: 16,
                    color: cs.outlineVariant),
                _TappableTile(
                  icon: Icons.star_outline_rounded,
                  title: 'Rate ScanVault',
                  onTap: () => launchUrl(
                    Uri.parse(AppConstants.playStoreUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                Divider(
                    height: 1,
                    indent: 56,
                    endIndent: 16,
                    color: cs.outlineVariant),
                _TappableTile(
                  icon: Icons.description_outlined,
                  title: 'Open Source Licenses',
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'ScanVault',
                    applicationLegalese:
                        '© 2024 ScanVault. All rights reserved.',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Footer
          Center(
            child: Text(
              'ScanVault — No ads. No account. Just scanning.',
              style:
                  AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    // Try to open the asset as an in-app web page or external URL
    final uri = Uri.parse(AppConstants.privacyPolicyUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } else {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Privacy Policy'),
            content: const SingleChildScrollView(
              child: Text(
                'ScanVault does not collect, transmit, or store any personal data.\n\n'
                'All scan history is stored locally on your device.\n\n'
                'This app contains no third-party SDKs, analytics, or advertising networks.\n\n'
                'Camera permission is used solely to scan QR codes and barcodes.\n\n'
                'Storage permission is used only when you explicitly export QR code images.',
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Got it'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _confirmClearHistory(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
            'This will permanently delete all your scan history. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(historyProvider.notifier).clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('History cleared')),
        );
      }
    }
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 0, 8),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: cs.primary),
      title: Text(title,
          style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style:
                  AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant))
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _TappableTile extends StatelessWidget {
  const _TappableTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: iconColor ?? cs.primary),
      title: Text(title,
          style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style:
                  AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant))
          : null,
      trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
      onTap: onTap,
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: cs.primary),
      title: Text(title,
          style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface)),
      trailing: Text(
        trailing,
        style: AppTextStyles.labelMedium.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}
