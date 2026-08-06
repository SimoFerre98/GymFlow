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
    this.primaryColor = defaultPrimaryColor,
  });

  /// Ambra: il colore delle azioni della palette Indigo.
  ///
  /// Il tema predefinito e scuro perche la palette e pensata cosi: il chiaro
  /// esiste per chi lo preferisce, non come punto di partenza.
  static const Color defaultPrimaryColor = AppPalette.amber;

  final ThemeMode themeMode;
  final Color primaryColor;

  ThemeSettings copyWith({ThemeMode? themeMode, Color? primaryColor}) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      primaryColor: primaryColor ?? this.primaryColor,
    );
  }
}

/// Espone modalità e colore del tema, persistendoli fra i riavvii.
///
/// [build] restituisce i valori di default in modo sincrono e avvia la
/// lettura da `SharedPreferences`: lo stato viene aggiornato appena i valori
/// salvati sono disponibili. In questo modo `MaterialApp` non deve gestire uno
/// stato di caricamento e all'avvio non si vede un cambio di tema.
@Riverpod(keepAlive: true)
class ThemeSettingsNotifier extends _$ThemeSettingsNotifier {
  static const _themeModeKey = 'theme_mode';
  static const _primaryColorKey = 'primary_color';

  @override
  ThemeSettings build() {
    _restore();
    return const ThemeSettings();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();

    final savedMode = prefs.getInt(_themeModeKey);
    final savedColor = prefs.getInt(_primaryColorKey);

    state = state.copyWith(
      themeMode: savedMode != null && savedMode >= 0
          ? ThemeMode.values.elementAtOrNull(savedMode)
          : null,
      primaryColor: savedColor != null ? Color(savedColor) : null,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  Future<void> setPrimaryColor(Color color) async {
    state = state.copyWith(primaryColor: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_primaryColorKey, color.toARGB32());
  }
}
