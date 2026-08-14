import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/theme/app_palette.dart';
import 'package:gymflow/src/core/theme/app_theme.dart';
import 'package:gymflow/src/core/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppThemeStyle enum e palette', () {
    test('ci sono quattro stili visivi totali', () {
      expect(AppThemeStyle.values.length, 4);
      expect(AppThemeStyle.values, containsAll([
        AppThemeStyle.defaultStyle,
        AppThemeStyle.digitalPulse,
        AppThemeStyle.toxicForest,
        AppThemeStyle.deepSeaNeon,
      ]));
    });

    test('ogni stile definisce sfondi e accenti validi e distinti', () {
      for (final style in AppThemeStyle.values) {
        expect(style.darkBackground, isNotNull);
        expect(style.darkSurface, isNotNull);
        expect(style.darkSurfaceHigh, isNotNull);
        expect(style.darkOutline, isNotNull);
        expect(style.defaultAccent, isNotNull);
        expect(style.defaultTertiary, isNotNull);
        expect(style.accentPresets, isNotEmpty);
        expect(style.accentPresets.length, greaterThanOrEqualTo(4));
      }
    });

    test('Digital Pulse ha i valori esadecimali conformi alla specifica', () {
      final s = AppThemeStyle.digitalPulse;
      expect(s.darkBackground, const Color(0xFF0F172A));
      expect(s.darkSurface, const Color(0xFF2E1065));
      expect(s.defaultAccent, const Color(0xFFF472B6));
      expect(s.defaultTertiary, const Color(0xFFDDD6FE));
    });

    test('Toxic Forest ha i valori esadecimali conformi alla specifica', () {
      final s = AppThemeStyle.toxicForest;
      expect(s.darkBackground, const Color(0xFF0B2027));
      expect(s.darkSurface, const Color(0xFF143540));
      expect(s.defaultAccent, const Color(0xFFEEF800));
      expect(s.defaultTertiary, const Color(0xFF80B918));
    });

    test('Deep Sea Neon ha i valori esadecimali conformi alla specifica', () {
      final s = AppThemeStyle.deepSeaNeon;
      expect(s.darkBackground, const Color(0xFF000814));
      expect(s.darkSurface, const Color(0xFF001D3D));
      expect(s.defaultAccent, const Color(0xFFFFC300));
      expect(s.defaultTertiary, const Color(0xFFFFD60A));
    });

    testWidgets('AppTheme genera temi scuri e chiari per tutti e 4 gli stili', (tester) async {
      for (final style in AppThemeStyle.values) {
        final darkTheme = AppTheme.darkTheme(style.defaultAccent, style: style);
        expect(darkTheme.brightness, Brightness.dark);
        expect(darkTheme.colorScheme.primary, style.defaultAccent);
        expect(darkTheme.colorScheme.surface, style.darkSurface);

        final lightTheme = AppTheme.lightTheme(style.defaultAccent, style: style);
        expect(lightTheme.brightness, Brightness.light);
        expect(lightTheme.colorScheme.surface, style.lightSurface);
      }
    });
  });

  group('ThemeSettings', () {
    test('copyWith aggiorna correttamente lo stile e il colore', () {
      const initial = ThemeSettings();
      expect(initial.themeStyle, AppThemeStyle.defaultStyle);

      final updated = initial.copyWith(
        themeStyle: AppThemeStyle.digitalPulse,
        primaryColor: AppThemeStyle.digitalPulse.defaultAccent,
      );

      expect(updated.themeStyle, AppThemeStyle.digitalPulse);
      expect(updated.primaryColor, const Color(0xFFF472B6));
    });
  });
}
