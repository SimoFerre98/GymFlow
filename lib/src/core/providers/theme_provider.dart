import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Color _primaryColor = const Color(0xFFD500F9); // Default Neon Purple

  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;

  ThemeProvider() {
    _loadTheme();
  }

  void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }

  void setPrimaryColor(Color color) async {
    _primaryColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primary_color', color.value);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt('theme_mode');
    if (savedIndex != null) {
      _themeMode = ThemeMode.values[savedIndex];
    }

    final savedColor = prefs.getInt('primary_color');
    if (savedColor != null) {
      _primaryColor = Color(savedColor);
    }
    notifyListeners();
  }
}
