import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../features/history/providers/history_provider.dart';

/// Persistent bottom navigation bar used in the shell route.
/// Watches [historyCountProvider] directly so the badge updates without
/// rebuilding the router's StatefulShellRoute (which would reset navigation).
class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyCount = ref.watch(historyCountProvider);

    return NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: _onDestinationSelected,
      animationDuration: const Duration(milliseconds: 300),
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.qr_code_scanner_outlined),
          selectedIcon: Icon(Icons.qr_code_scanner),
          label: 'Scan',
        ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: historyCount > 0,
            label: Text(
              historyCount > 99 ? '99+' : '$historyCount',
              style: const TextStyle(fontSize: 10),
            ),
            child: const Icon(Icons.history_outlined),
          ),
          selectedIcon: Badge(
            isLabelVisible: historyCount > 0,
            label: Text(
              historyCount > 99 ? '99+' : '$historyCount',
              style: const TextStyle(fontSize: 10),
            ),
            backgroundColor: AppColors.brandTeal,
            child: const Icon(Icons.history),
          ),
          label: 'History',
        ),
        const NavigationDestination(
          icon: Icon(Icons.qr_code_outlined),
          selectedIcon: Icon(Icons.qr_code),
          label: 'Generate',
        ),
        const NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}
