import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/hive_service.dart';
import '../../scanner/domain/scan_result_model.dart';

/// Manages the scan history stored in Hive.
class HistoryNotifier extends AsyncNotifier<List<ScanResultModel>> {
  @override
  Future<List<ScanResultModel>> build() async {
    return _loadAll();
  }

  List<ScanResultModel> _loadAll() {
    final box = HiveService.historyBox;
    final items = box.values.toList()
      ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return items;
  }

  /// Adds a new scan result to history.
  Future<void> addScan(ScanResultModel result) async {
    final box = HiveService.historyBox;
    await box.put(result.id, result);
    state = AsyncData(_loadAll());
  }

  /// Deletes a single scan result by its ID key.
  Future<void> deleteScan(String id) async {
    final box = HiveService.historyBox;
    await box.delete(id);
    state = AsyncData(_loadAll());
  }

  /// Clears all history.
  Future<void> clearAll() async {
    final box = HiveService.historyBox;
    await box.clear();
    state = const AsyncData([]);
  }

  /// Toggles the favorite status of a scan.
  Future<void> toggleFavorite(String id) async {
    final box = HiveService.historyBox;
    final item = box.get(id);
    if (item == null) return;
    item.isFavorite = !item.isFavorite;
    await item.save();
    state = AsyncData(_loadAll());
  }

  /// Returns filtered results matching [query].
  List<ScanResultModel> search(List<ScanResultModel> items, String query) {
    if (query.isEmpty) return items;
    final q = query.toLowerCase();
    return items
        .where((item) => item.rawContent.toLowerCase().contains(q))
        .toList();
  }

  /// Returns count of history items.
  int get count => HiveService.historyBox.length;
}

final historyProvider =
    AsyncNotifierProvider<HistoryNotifier, List<ScanResultModel>>(
  HistoryNotifier.new,
);

/// Exposes only the count for the badge.
final historyCountProvider = Provider<int>((ref) {
  final history = ref.watch(historyProvider);
  return history.maybeWhen(data: (list) => list.length, orElse: () => 0);
});
