/// App-wide constants for ScanVault
class AppConstants {
  AppConstants._();

  // Hive box names
  static const String scanHistoryBox = 'scan_history';

  // SharedPreferences keys
  static const String themeModeKey = 'theme_mode';
  static const String vibrationKey = 'vibration_enabled';
  static const String soundKey = 'sound_enabled';
  static const String autoOpenUrlKey = 'auto_open_url';
  static const String saveHistoryKey = 'save_history_enabled';

  // App info
  static const String appName = 'ScanVault';
  static const String privacyPolicyAsset = 'assets/privacy_policy.html';
  static const String privacyPolicyUrl =
      'https://nomidevx.github.io/qrcodescanner_vaultscanner/assets/privacy_policy.html';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.nomidevx.scanvault';

  // Scanner
  static const double scanWindowSize = 280.0;
  static const int scanDebounceMs = 500;
}
