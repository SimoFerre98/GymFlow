import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/theme/app_palette.dart';
import 'package:gymflow/src/core/theme/app_theme.dart';
import 'package:gymflow/src/core/theme/contrast.dart';

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

      testWidgets('il preset $i nel tema scuro supera AA', (tester) async {
        final s = AppTheme.darkTheme(c).colorScheme;
        
        final rBg = Contrast.ratio(s.primary, s.surfaceContainerLowest);
        expect(
          rBg,
          greaterThanOrEqualTo(Contrast.aa),
          reason: 'preset $i scuro (primary su surfaceContainerLowest): ${rBg.toStringAsFixed(2)}:1',
        );

        final rCard = Contrast.ratio(s.primary, s.surface);
        expect(
          rCard,
          greaterThanOrEqualTo(Contrast.aa),
          reason: 'preset $i scuro (primary su surface): ${rCard.toStringAsFixed(2)}:1',
        );

        final rBtn = Contrast.ratio(s.onPrimary, s.primary);
        expect(
          rBtn,
          greaterThanOrEqualTo(Contrast.aa),
          reason: 'preset $i scuro (onPrimary su primary): ${rBtn.toStringAsFixed(2)}:1',
        );
      });

      testWidgets('il preset $i nel tema chiaro supera AA', (tester) async {
        final s = AppTheme.lightTheme(c).colorScheme;
        
        final rBtn = Contrast.ratio(s.onPrimaryContainer, s.primaryContainer);
        expect(
          rBtn,
          greaterThanOrEqualTo(Contrast.aa),
          reason: 'preset $i chiaro (onPrimaryContainer su primaryContainer): ${rBtn.toStringAsFixed(2)}:1',
        );
      });
    }
  });

  group('segnaposto degli esercizi', () {
    testWidgets('la sagoma si vede su entrambi gli estremi del gradiente, tema scuro', (
      tester,
    ) async {
      final s = AppTheme.darkTheme(AppPalette.amber).colorScheme;
      final glyphColor = s.onSurface.withValues(alpha: 0.92);

      final rStart = Contrast.ratio(glyphColor, s.outline);
      final rEnd = Contrast.ratio(glyphColor, s.surfaceContainer);

      expect(
        rStart,
        greaterThanOrEqualTo(Contrast.aaLarge),
        reason: 'inizio gradiente scuro: ${rStart.toStringAsFixed(2)}:1',
      );
      expect(
        rEnd,
        greaterThanOrEqualTo(Contrast.aaLarge),
        reason: 'fine gradiente scuro: ${rEnd.toStringAsFixed(2)}:1',
      );
    });

    testWidgets('la sagoma si vede su entrambi gli estremi del gradiente, tema chiaro', (
      tester,
    ) async {
      final s = AppTheme.lightTheme(AppPalette.amber).colorScheme;
      final glyphColor = s.onSurface.withValues(alpha: 0.92);

      final rStart = Contrast.ratio(glyphColor, s.outline);
      final rEnd = Contrast.ratio(glyphColor, s.surfaceContainer);

      expect(
        rStart,
        greaterThanOrEqualTo(Contrast.aaLarge),
        reason: 'inizio gradiente chiaro: ${rStart.toStringAsFixed(2)}:1',
      );
      expect(
        rEnd,
        greaterThanOrEqualTo(Contrast.aaLarge),
        reason: 'fine gradiente chiaro: ${rEnd.toStringAsFixed(2)}:1',
      );
    });
  });

  group('indicatore del video sulla miniatura', () {
    testWidgets('il simbolo si vede sul fondo del badge, tema scuro', (
      tester,
    ) async {
      final s = AppTheme.darkTheme(AppPalette.amber).colorScheme;
      final r = Contrast.ratio(s.onTertiary, s.tertiary);
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
      final r = Contrast.ratio(s.onTertiary, s.tertiary);
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
