import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/history_provider.dart';
import 'package:scanvault/features/scanner/domain/scan_result_model.dart';
import 'package:scanvault/features/scanner/presentation/widgets/result_sheet.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../app/theme/app_text_styles.dart';
import 'widgets/history_tile.dart';

enum _SortMode { newest, oldest, byType }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _searchQuery = '';
  _SortMode _sortMode = _SortMode.newest;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ScanResultModel> _applyFilters(List<ScanResultModel> items) {
    // Search filter
    final filtered = _searchQuery.isEmpty
        ? items
        : items
            .where((i) =>
                i.rawContent.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    // Sort
    switch (_sortMode) {
      case _SortMode.newest:
        filtered.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
      case _SortMode.oldest:
        filtered.sort((a, b) => a.scannedAt.compareTo(b.scannedAt));
      case _SortMode.byType:
        filtered.sort((a, b) => a.type.name.compareTo(b.type.name));
    }
    return filtered;
  }

  void _showDetail(BuildContext context, ScanResultModel result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ResultSheet(
        result: result,
        onScanNext: () => Navigator.of(ctx).pop(),
        readOnly: true,
      ),
    );
  }


  Future<void> _confirmClearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
            'This will permanently delete all your scan history. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(historyProvider.notifier).clearAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          // Sort menu
          PopupMenuButton<_SortMode>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort',
            onSelected: (mode) => setState(() => _sortMode = mode),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: _SortMode.newest,
                child: Text('Newest first'),
              ),
              const PopupMenuItem(
                value: _SortMode.oldest,
                child: Text('Oldest first'),
              ),
              const PopupMenuItem(
                value: _SortMode.byType,
                child: Text('By type'),
              ),
            ],
          ),
          // Clear all
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Clear all',
            onPressed: () => _confirmClearAll(context),
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allItems) {
          final items = _applyFilters(allItems);
          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search scans...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
              ),

              // Count label
              if (allItems.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        '${items.length} scan${items.length == 1 ? '' : 's'}',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),

              // List
              Expanded(
                child: items.isEmpty
                    ? EmptyState(
                        icon: Icons.history_rounded,
                        title: allItems.isEmpty
                            ? 'No scans yet'
                            : 'No results found',
                        subtitle: allItems.isEmpty
                            ? 'Point your camera at a QR code to get started.'
                            : 'Try a different search term.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: items.length,
                        itemBuilder: (ctx, i) => HistoryTile(
                          result: items[i],
                          onTap: () => _showDetail(context, items[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
