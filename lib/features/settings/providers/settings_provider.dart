import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';

// ---------------------------------------------------------------------------
// Shared Preferences provider
// ---------------------------------------------------------------------------

final sharedPrefsProvider = FutureProvider<SharedPreferences>(
  (ref) async => SharedPreferences.getInstance(),
);

// ---------------------------------------------------------------------------
// Theme Mode Notifier
// ---------------------------------------------------------------------------

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Default to system, then load persisted value asynchronously
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.themeModeKey);
    if (raw != null) {
      final mode = ThemeMode.values.firstWhere(
        (m) => m.name == raw,
        orElse: () => ThemeMode.system,
      );
      state = mode;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.themeModeKey, mode.name);
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setMode(next);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

// ---------------------------------------------------------------------------
// App Settings Notifier
// ---------------------------------------------------------------------------

class AppSettings {
  final bool vibrationEnabled;
  final bool soundEnabled;
  final bool autoOpenUrl;
  final bool saveHistory;

  const AppSettings({
    this.vibrationEnabled = true,
    this.soundEnabled = false,
    this.autoOpenUrl = false,
    this.saveHistory = true,
  });

  AppSettings copyWith({
    bool? vibrationEnabled,
    bool? soundEnabled,
    bool? autoOpenUrl,
    bool? saveHistory,
  }) {
    return AppSettings(
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      autoOpenUrl: autoOpenUrl ?? this.autoOpenUrl,
      saveHistory: saveHistory ?? this.saveHistory,
    );
  }
}

class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      vibrationEnabled:
          prefs.getBool(AppConstants.vibrationKey) ?? true,
      soundEnabled: prefs.getBool(AppConstants.soundKey) ?? false,
      autoOpenUrl: prefs.getBool(AppConstants.autoOpenUrlKey) ?? false,
      saveHistory: prefs.getBool(AppConstants.saveHistoryKey) ?? true,
    );
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.vibrationKey, state.vibrationEnabled);
    await prefs.setBool(AppConstants.soundKey, state.soundEnabled);
    await prefs.setBool(AppConstants.autoOpenUrlKey, state.autoOpenUrl);
    await prefs.setBool(AppConstants.saveHistoryKey, state.saveHistory);
  }

  Future<void> setVibration(bool value) async {
    state = state.copyWith(vibrationEnabled: value);
    await _persist();
  }

  Future<void> setSound(bool value) async {
    state = state.copyWith(soundEnabled: value);
    await _persist();
  }

  Future<void> setAutoOpenUrl(bool value) async {
    state = state.copyWith(autoOpenUrl: value);
    await _persist();
  }

  Future<void> setSaveHistory(bool value) async {
    state = state.copyWith(saveHistory: value);
    await _persist();
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
