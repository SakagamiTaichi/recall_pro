import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_provider.g.dart';

enum AppThemeMode {
  light,
  dark,
  system, // default
}

extension AppThemeModeExtension on AppThemeMode {
  ThemeMode get themeMode {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  String get displayName {
    switch (this) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }
}

@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  @override
  AppThemeMode build() {
    return AppThemeMode.system; // default
  }

  void setTheme(AppThemeMode mode) {
    state = mode;
  }

  void toggleTheme() {
    switch (state) {
      case AppThemeMode.light:
        state = AppThemeMode.dark;
        break;
      case AppThemeMode.dark:
        state = AppThemeMode.system;
        break;
      case AppThemeMode.system:
        state = AppThemeMode.light;
        break;
    }
  }
}
