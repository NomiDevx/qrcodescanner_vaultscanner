import 'package:hive_flutter/hive_flutter.dart';
import '../../features/scanner/domain/scan_result_model.dart';
import '../constants/app_constants.dart';

/// Handles Hive initialization and provides typed box accessors.
class HiveService {
  HiveService._();

  /// Initialize Hive and register all adapters.
  /// Call this before [runApp].
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(ScanResultModelAdapter().typeId)) {
      Hive.registerAdapter(ScanResultModelAdapter());
    }
    if (!Hive.isAdapterRegistered(ScanTypeAdapter().typeId)) {
      Hive.registerAdapter(ScanTypeAdapter());
    }

    // Open boxes
    await Hive.openBox<ScanResultModel>(AppConstants.scanHistoryBox);
  }

  /// Returns the scan history box.
  static Box<ScanResultModel> get historyBox =>
      Hive.box<ScanResultModel>(AppConstants.scanHistoryBox);
}
