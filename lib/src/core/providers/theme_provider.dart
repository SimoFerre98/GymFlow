import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_palette.dart';

part 'theme_provider.g.dart';

/// Preferenze di aspetto scelte dall'utente.
@immutable
class ThemeSettings {
  const ThemeSettings({
    this.themeMode = ThemeMode.dark,
    this.themeStyle = AppThemeStyle.defaultStyle,
    this.primaryColor = defaultPrimaryColor,
    this.hapticFeedback = true,
  });

  /// Ambra: il colore delle azioni della palette Indigo predefinita.
  static const Color defaultPrimaryColor = AppPalette.amber;

  final ThemeMode themeMode;
  final AppThemeStyle themeStyle;
  final Color primaryColor;

  /// Vibra a ogni tocco che disegna un'onda materiale — bottoni, righe di
  /// lista, chip, switch. Acceso per impostazione predefinita.
  final bool hapticFeedback;

  ThemeSettings copyWith({
    ThemeMode? themeMode,
    AppThemeStyle? themeStyle,
    Color? primaryColor,
    bool? hapticFeedback,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      themeStyle: themeStyle ?? this.themeStyle,
      primaryColor: primaryColor ?? this.primaryColor,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
    );
  }
}

/// Espone modalità, stile e colore del tema, persistendoli fra i riavvii.
@Riverpod(keepAlive: true)
class ThemeSettingsNotifier extends _$ThemeSettingsNotifier {
  static const _themeModeKey = 'theme_mode';
  static const _themeStyleKey = 'theme_style';
  static const _primaryColorKey = 'primary_color';
  static const _hapticFeedbackKey = 'haptic_feedback';

  @override
  ThemeSettings build() {
    _restore();
    return const ThemeSettings();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedMode = prefs.getInt(_themeModeKey);
      final savedStyle = prefs.getInt(_themeStyleKey);
      final savedColor = prefs.getInt(_primaryColorKey);
      final savedHaptic = prefs.getBool(_hapticFeedbackKey);

      final style = savedStyle != null && savedStyle >= 0 && savedStyle < AppThemeStyle.values.length
          ? AppThemeStyle.values[savedStyle]
          : AppThemeStyle.defaultStyle;

      state = state.copyWith(
        themeMode: savedMode != null && savedMode >= 0
            ? ThemeMode.values.elementAtOrNull(savedMode)
            : null,
        themeStyle: style,
        primaryColor: savedColor != null ? Color(savedColor) : style.defaultAccent,
        hapticFeedback: savedHaptic,
      );
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, mode.index);
    } catch (_) {}
  }

  Future<void> setThemeStyle(AppThemeStyle style) async {
    state = state.copyWith(
      themeStyle: style,
      primaryColor: style.defaultAccent,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeStyleKey, style.index);
      await prefs.setInt(_primaryColorKey, style.defaultAccent.toARGB32());
    } catch (_) {}
  }

  Future<void> setPrimaryColor(Color color) async {
    state = state.copyWith(primaryColor: color);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_primaryColorKey, color.toARGB32());
    } catch (_) {}
  }

  Future<void> setHapticFeedback(bool enabled) async {
    state = state.copyWith(hapticFeedback: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hapticFeedbackKey, enabled);
    } catch (_) {}
  }
}
