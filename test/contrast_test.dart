import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/theme/app_palette.dart';
import 'package:gymflow/src/core/theme/app_theme.dart';
import 'package:gymflow/src/core/theme/contrast.dart';
import 'package:gymflow/src/core/theme/muscle_group_visuals.dart';

/// Questi test sono la rete che impedisce all'accessibilita di regredire in
/// silenzio. Senza, basta ritoccare un colore per rendere illeggibile del
/// testo e accorgersene solo quando lo segnala qualcuno.
void main() {
  group('calcolo del rapporto WCAG', () {
    test('bianco su nero da il massimo teorico di 21', () {
      expect(
        Contrast.ratio(const Color(0xFFFFFFFF), const Color(0xFF000000)),
        closeTo(21.0, 0.01),
      );
    });

    test('due colori identici danno 1', () {
      expect(
        Contrast.ratio(AppPalette.amber, AppPalette.amber),
        closeTo(1.0, 0.001),
      );
    });

    test('l ordine degli argomenti non conta', () {
      final a = Contrast.ratio(AppPalette.paper, AppPalette.indigo900);
      final b = Contrast.ratio(AppPalette.indigo900, AppPalette.paper);
      expect(a, closeTo(b, 0.0001));
    });
  });

  group('coppie usate dall interfaccia scura', () {
    // I valori attesi sono quelli misurati quando la palette e stata scelta.
    // Se una di queste righe fallisce, un colore e stato cambiato: va deciso
    // se il nuovo valore e accettabile, non zittito il test.
    final pairs = <String, ({Color fg, Color bg, double min})>{
      'testo su fondo': (
        fg: AppPalette.paper,
        bg: AppPalette.indigo900,
        min: Contrast.aaa,
      ),
      'testo su superficie': (
        fg: AppPalette.paper,
        bg: AppPalette.indigo800,
        min: Contrast.aaa,
      ),
      'testo su superficie sollevata': (
        fg: AppPalette.paper,
        bg: AppPalette.indigo700,
        min: Contrast.aa,
      ),
      'testo secondario su fondo': (
        fg: AppPalette.paperDim,
        bg: AppPalette.indigo900,
        min: Contrast.aa,
      ),
      'ambra su fondo': (
        fg: AppPalette.amber,
        bg: AppPalette.indigo900,
        min: Contrast.aaa,
      ),
      'ambra su superficie': (
        fg: AppPalette.amber,
        bg: AppPalette.indigo800,
        min: Contrast.aa,
      ),
      'salmone su fondo': (
        fg: AppPalette.salmon,
        bg: AppPalette.indigo900,
        min: Contrast.aa,
      ),
      'salmone su superficie': (
        fg: AppPalette.salmon,
        bg: AppPalette.indigo800,
        min: Contrast.aa,
      ),
      'testo su bottone ambra': (
        fg: AppPalette.indigo900,
        bg: AppPalette.amber,
        min: Contrast.aaa,
      ),
      'testo su bottone salmone': (
        fg: AppPalette.indigo900,
        bg: AppPalette.salmon,
        min: Contrast.aa,
      ),
    };

    pairs.forEach((label, p) {
      test('$label supera la soglia richiesta', () {
        final r = Contrast.ratio(p.fg, p.bg);
        expect(
          r,
          greaterThanOrEqualTo(p.min),
          reason:
              '$label: ${r.toStringAsFixed(2)}:1 '
              '(${Contrast.level(p.fg, p.bg)}), richiesto ${p.min}',
        );
      });
    });
  });

  group('preset del colore delle azioni', () {
    test('ce ne sono almeno quattro fra cui scegliere', () {
      expect(AppPalette.accentPresets.length, greaterThanOrEqualTo(4));
    });

    test('il primo preset e l ambra predefinita', () {
      expect(AppPalette.accentPresets.first, AppPalette.amber);
    });

    for (var i = 0; i < AppPalette.accentPresets.length; i++) {
      final c = AppPalette.accentPresets[i];

      test('il preset $i e leggibile come testo sul fondo', () {
        final r = Contrast.ratio(c, AppPalette.indigo900);
        expect(
          r,
          greaterThanOrEqualTo(Contrast.aa),
          reason: 'preset $i: ${r.toStringAsFixed(2)}:1 sul fondo',
        );
      });

      test('il preset $i e leggibile come testo sulle card', () {
        final r = Contrast.ratio(c, AppPalette.indigo800);
        expect(
          r,
          greaterThanOrEqualTo(Contrast.aa),
          reason: 'preset $i: ${r.toStringAsFixed(2)}:1 sulle card',
        );
      });

      test('il preset $i regge il testo scuro sopra di se', () {
        final r = Contrast.ratio(AppPalette.indigo900, c);
        expect(
          r,
          greaterThanOrEqualTo(Contrast.aa),
          reason: 'preset $i come sfondo di un bottone: ${r.toStringAsFixed(2)}:1',
        );
      });
    }
  });

  group('segnaposto degli esercizi', () {
    for (final region in BodyRegion.values) {
      test('la sagoma di ${region.name} si vede sul suo fondo', () {
        // WCAG 1.4.11: un elemento grafico che porta informazione richiede 3:1.
        // La sagoma e l'unica cosa che distingue due segnaposti della stessa
        // regione, quindi deve essere leggibile, non solo presente.
        final r = Contrast.ratio(AppPalette.regionGlyph, region.tint);
        expect(
          r,
          greaterThanOrEqualTo(Contrast.aaLarge),
          reason: '${region.name}: ${r.toStringAsFixed(2)}:1',
        );
      });

      test('la sagoma di ${region.name} si vede anche sul fondo profondo', () {
        // Il gradiente scurisce: se il controllo fosse solo sulla tinta chiara,
        // l'angolo in basso a destra potrebbe cadere sotto soglia.
        final r = Contrast.ratio(AppPalette.regionGlyph, region.tintDeep);
        expect(
          r,
          greaterThanOrEqualTo(Contrast.aaLarge),
          reason: '${region.name} profondo: ${r.toStringAsFixed(2)}:1',
        );
      });

      test('${region.name} legge come superficie, non come accento', () {
        // In questa app l'ambra significa "cosa fare adesso" e il salmone
        // "dato vitale". Un segnaposto che somigliasse a uno dei due
        // insegnerebbe all'occhio a non fidarsi piu di quel colore.
        expect(
          region.tint.computeLuminance(),
          lessThan(AppPalette.indigo400.computeLuminance()),
          reason:
              '${region.name} e troppo chiaro: a questa luminosita competerebbe '
              'con gli accenti invece di stare sotto il contenuto',
        );
      });
    }
  });

  group('indicatore del video sulla miniatura', () {
    // Il badge e opaco di proposito: sopra una fotografia qualunque, il
    // contrasto di un fondo translucido non e calcolabile, quindi non e
    // verificabile. Opaco si misura, ed e questo il posto dove si misura.
    //
    // I temi si costruiscono dentro il test e non a fianco: `AppTheme` passa da
    // GoogleFonts, che ha bisogno del binding, e il binding esiste solo dentro
    // un caso di prova.
    testWidgets('il simbolo si vede sul fondo del badge, tema scuro', (
      tester,
    ) async {
      final s = AppTheme.darkTheme(AppPalette.amber).colorScheme;
      final r = Contrast.ratio(s.onSurface, s.surfaceContainerLowest);
      expect(
        r,
        greaterThanOrEqualTo(Contrast.aaLarge),
        reason: 'badge scuro: ${r.toStringAsFixed(2)}:1',
      );
    });

    testWidgets('il simbolo si vede sul fondo del badge, tema chiaro', (
      tester,
    ) async {
      final s = AppTheme.lightTheme(AppPalette.amber).colorScheme;
      final r = Contrast.ratio(s.onSurface, s.surfaceContainerLowest);
      expect(
        r,
        greaterThanOrEqualTo(Contrast.aaLarge),
        reason: 'badge chiaro: ${r.toStringAsFixed(2)}:1',
      );
    });
  });

  group('coppie del tema chiaro', () {
    testWidgets('i ruoli testuali del tema chiaro superano AA', (tester) async {
      final s = AppTheme.lightTheme(AppPalette.amber).colorScheme;

      final checks = <String, ({Color fg, Color bg})>{
        'testo su superficie': (fg: s.onSurface, bg: s.surface),
        'testo secondario su superficie': (fg: s.onSurfaceVariant, bg: s.surface),
        'testo su fondo': (fg: s.onSurface, bg: s.surfaceContainerLowest),
        'primario su superficie': (fg: s.primary, bg: s.surface),
        'terziario su superficie': (fg: s.tertiary, bg: s.surface),
        'testo su primario': (fg: s.onPrimary, bg: s.primary),
      };

      checks.forEach((label, p) {
        final r = Contrast.ratio(p.fg, p.bg);
        expect(
          r,
          greaterThanOrEqualTo(Contrast.aa),
          reason: 'chiaro, $label: ${r.toStringAsFixed(2)}:1',
        );
      });
    });

    testWidgets('i ruoli testuali del tema scuro superano AA', (tester) async {
      final s = AppTheme.darkTheme(AppPalette.amber).colorScheme;

      final checks = <String, ({Color fg, Color bg})>{
        'testo su superficie': (fg: s.onSurface, bg: s.surface),
        'testo secondario su superficie': (fg: s.onSurfaceVariant, bg: s.surface),
        'testo su fondo': (fg: s.onSurface, bg: s.surfaceContainerLowest),
        'primario su superficie': (fg: s.primary, bg: s.surface),
        'terziario su superficie': (fg: s.tertiary, bg: s.surface),
        'testo su primario': (fg: s.onPrimary, bg: s.primary),
        'testo su terziario': (fg: s.onTertiary, bg: s.tertiary),
      };

      checks.forEach((label, p) {
        final r = Contrast.ratio(p.fg, p.bg);
        expect(
          r,
          greaterThanOrEqualTo(Contrast.aa),
          reason: 'scuro, $label: ${r.toStringAsFixed(2)}:1',
        );
      });
    });
  });
}
