import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/theme/app_palette.dart';
import 'package:gymflow/src/core/theme/app_theme.dart';
import 'package:gymflow/src/core/theme/contrast.dart';

/// Nel tema chiaro l'accento scelto dall'utente in Aspetto deve guidare i ruoli
/// d'azione, come nello scuro.
///
/// Prima `lightTheme` ignorava la scelta: `primary` era sempre il tono fisso
/// della palette e l'accento arrivava solo a `primaryContainer`. Il test di
/// `contrast_test.dart` sui preset del chiaro guardava solo quella coppia, e
/// per questo non se ne accorgeva: qui si guarda `primary`, cioe quello che
/// disegnano bottoni, interruttori, barra di navigazione e testi d'azione.
void main() {
  // I test che costruiscono un tema sono `testWidgets`, non `test`: google_fonts
  // segnala in modo asincrono i font che non trova, e solo `testWidgets` regge
  // quell'errore (stessa scelta di `contrast_test.dart`).
  group('Contrast.darkenToMeet', () {
    const bianco = Color(0xFFFFFFFF);

    test('un colore che gia passa torna invariato', () {
      const scuro = Color(0xFF1A2B2B);
      expect(Contrast.darkenToMeet(scuro, [bianco]), scuro);
    });

    test('scurisce un colore troppo chiaro fino alla soglia, senza superarla di molto', () {
      const neon = Color(0xFF00F5D4);
      final risultato = Contrast.darkenToMeet(neon, [bianco]);
      final r = Contrast.ratio(risultato, bianco);
      expect(r, greaterThanOrEqualTo(Contrast.aa));
      // Un passo di luminosita in piu e si sarebbe scurito senza motivo.
      expect(r, lessThan(Contrast.aa + 0.5));
    });

    test('mantiene la tinta: e lo stesso colore piu scuro, non un altro', () {
      const neon = Color(0xFF00F5D4);
      final risultato = Contrast.darkenToMeet(neon, [bianco]);
      final prima = HSLColor.fromColor(neon);
      final dopo = HSLColor.fromColor(risultato);
      expect(dopo.hue, closeTo(prima.hue, 3));
      expect(dopo.lightness, lessThan(prima.lightness));
    });

    test('deve passare contro tutti gli sfondi, non solo il primo', () {
      const medio = Color(0xFF808080);
      final scuroDelBianco = Contrast.darkenToMeet(medio, [bianco]);
      final scuroDiTutti = Contrast.darkenToMeet(medio, [
        bianco,
        const Color(0xFFE0ECEF),
      ]);
      expect(
        Contrast.ratio(scuroDiTutti, const Color(0xFFE0ECEF)),
        greaterThanOrEqualTo(Contrast.aa),
      );
      expect(
        HSLColor.fromColor(scuroDiTutti).lightness,
        lessThan(HSLColor.fromColor(scuroDelBianco).lightness),
      );
    });

    test('con una soglia irraggiungibile termina comunque', () {
      final risultato = Contrast.darkenToMeet(
        const Color(0xFF00F5D4),
        [bianco],
        min: 25,
      );
      expect(risultato, const Color(0xFF000000));
    });
  });

  for (final style in AppThemeStyle.values) {
    group('tema chiaro, palette ${style.name}', () {
      final fondi = <String, Color>{
        'fondo': style.lightBackground,
        'superficie': style.lightSurface,
        'superficie alternativa': style.lightSurfaceAlt,
      };

      testWidgets('con l accento predefinito resta il tono scelto a mano', (tester) async {
        final s = AppTheme.lightTheme(style.defaultAccent, style: style).colorScheme;
        expect(s.primary, style.accentOnLight);
      });

      testWidgets('ogni preset produce un primary diverso: la scelta si vede', (tester) async {
        final primari = {
          for (final preset in style.accentPresets)
            AppTheme.lightTheme(preset, style: style).colorScheme.primary.toARGB32(),
        };
        expect(
          primari.length,
          style.accentPresets.length,
          reason: 'due preset diversi non devono finire sullo stesso colore',
        );
      });

      for (var i = 0; i < style.accentPresets.length; i++) {
        final preset = style.accentPresets[i];

        testWidgets('il preset $i: primary leggibile su ogni fondo chiaro', (tester) async {
          final s = AppTheme.lightTheme(preset, style: style).colorScheme;
          fondi.forEach((nome, fondo) {
            final r = Contrast.ratio(s.primary, fondo);
            expect(
              r,
              greaterThanOrEqualTo(Contrast.aa),
              reason: 'preset $i, primary su $nome: ${r.toStringAsFixed(2)}:1',
            );
          });
        });

        testWidgets('il preset $i: il testo sul bottone (onPrimary) e leggibile', (tester) async {
          final s = AppTheme.lightTheme(preset, style: style).colorScheme;
          final r = Contrast.ratio(s.onPrimary, s.primary);
          expect(
            r,
            greaterThanOrEqualTo(Contrast.aa),
            reason: 'preset $i, onPrimary su primary: ${r.toStringAsFixed(2)}:1',
          );
        });

        testWidgets('il preset $i: resta lo stesso colore, solo piu scuro', (tester) async {
          final s = AppTheme.lightTheme(preset, style: style).colorScheme;
          if (preset.toARGB32() == style.defaultAccent.toARGB32()) return;
          final scelto = HSLColor.fromColor(preset);
          final usato = HSLColor.fromColor(s.primary);
          // Una tinta quasi grigia (saturazione bassa) puo spostarsi nel
          // calcolo della tinta: il controllo ha senso solo dove la tinta e
          // ben definita.
          if (scelto.saturation > 0.2) {
            expect(usato.hue, closeTo(scelto.hue, 4));
          }
          expect(usato.lightness, lessThanOrEqualTo(scelto.lightness));
        });
      }
    });
  }

  testWidgets('il tema scuro non e cambiato: primary e l accento scelto, tale e quale', (tester) async {
    for (final style in AppThemeStyle.values) {
      for (final preset in style.accentPresets) {
        expect(
          AppTheme.darkTheme(preset, style: style).colorScheme.primary,
          preset,
        );
      }
    }
  });

  testWidgets('l accento crudo resta sul contenitore, dove serve come fondo vivace', (tester) async {
    final s = AppTheme.lightTheme(AppPalette.accentPresets[2]).colorScheme;
    expect(s.primaryContainer, AppPalette.accentPresets[2]);
  });
}
