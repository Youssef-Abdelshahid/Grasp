import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const themeModeLight = 'light';
const themeModeDark = 'dark';

final themeModeProvider =
    AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(
      ThemeModeNotifier.new,
    );

class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  static const _prefKey = 'grasp.theme_mode';

  @override
  Future<ThemeMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    return _fromString(prefs.getString(_prefKey));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AsyncData(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, mode.name);
  }

  Future<void> syncFromBackend(String? value) async {
    final mode = _fromString(value);
    if (state.valueOrNull == mode) {
      return;
    }
    await setThemeMode(mode);
  }

  static ThemeMode _fromString(String? value) {
    switch (value) {
      case themeModeDark:
        return ThemeMode.dark;
      case themeModeLight:
      default:
        return ThemeMode.light;
    }
  }
}

extension ThemeModeLabels on ThemeMode {
  String get storageValue {
    return this == ThemeMode.dark ? themeModeDark : themeModeLight;
  }

  String get displayLabel {
    return this == ThemeMode.dark ? 'Dark' : 'Light';
  }
}
