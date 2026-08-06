import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/theme/app_theme.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';

void main() {
  // Questi due sono testWidgets e non test semplici perche costruire un
  // AppTheme fa risolvere la scala tipografica a GoogleFonts, che senza rete
  // ne font negli asset solleva un'eccezione. L'ambiente widget la tollera,
  // quello unitario no. Cio che si verifica non cambia.
  group('ExpressiveTokens registrati nel tema', () {
    testWidgets('il tema chiaro espone i token', (tester) async {
      final theme = AppTheme.lightTheme(const Color(0xFFD500F9));
      expect(theme.extension<ExpressiveTokens>(), isNotNull);
    });

    testWidgets('il tema scuro espone i token', (tester) async {
      final theme = AppTheme.darkTheme(const Color(0xFFD500F9));
      expect(theme.extension<ExpressiveTokens>(), isNotNull);
    });
  });

  group('accesso dal contesto', () {
    testWidgets('context.expressive legge i token registrati', (tester) async {
      late ExpressiveTokens read;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(const Color(0xFFD500F9)),
          home: Builder(
            builder: (context) {
              read = context.expressive;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(read.spacing.md, 16);
    });

    testWidgets('senza estensione registrata restituisce i default', (
      tester,
    ) async {
      late ExpressiveTokens read;

      // Un widget non deve rompersi se finisce in un albero senza tema
      // completo: e il caso tipico di un test isolato.
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              read = context.expressive;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(read.spacing.md, 16);
      expect(read.shape.radiusLg, 24);
    });
  });

  group('contratto della scala', () {
    test('le spaziature crescono in modo monotono', () {
      const s = ExpressiveSpacing();
      final scale = [s.xs, s.sm, s.md, s.lg, s.xl, s.xxl];
      for (var i = 1; i < scale.length; i++) {
        expect(
          scale[i],
          greaterThan(scale[i - 1]),
          reason: 'la scala deve crescere: ${scale[i]} dopo ${scale[i - 1]}',
        );
      }
    });

    test('i raggi crescono in modo monotono', () {
      const sh = ExpressiveShape();
      final scale = [
        sh.radiusXs,
        sh.radiusSm,
        sh.radiusMd,
        sh.radiusLg,
        sh.radiusXl,
        sh.radiusFull,
      ];
      for (var i = 1; i < scale.length; i++) {
        expect(scale[i], greaterThan(scale[i - 1]));
      }
    });

    test('le durate crescono in modo monotono', () {
      const m = ExpressiveMotion();
      final scale = [
        m.instant,
        m.quick,
        m.standard,
        m.emphasized,
        m.expressive,
      ];
      for (var i = 1; i < scale.length; i++) {
        expect(scale[i], greaterThan(scale[i - 1]));
      }
    });

    test('le durate provengono dai token nativi di Flutter', () {
      const m = ExpressiveMotion();
      // Se un domani si smettesse di rimandare ai token nativi, questo test
      // lo segnalerebbe: e una scelta dell'ADR, non un dettaglio.
      expect(m.instant, Durations.short2);
      expect(m.standard, Durations.medium2);
      expect(m.expressive, Durations.extralong2);
    });
  });

  group('copyWith e lerp', () {
    test('copyWith sostituisce solo la categoria indicata', () {
      const original = ExpressiveTokens();
      final copy = original.copyWith(spacing: const _DoubleSpacing());

      expect(copy.spacing.md, 32);
      expect(copy.shape.radiusLg, original.shape.radiusLg);
    });

    test('lerp restituisce uno dei due estremi, senza interpolare', () {
      const a = ExpressiveTokens();
      final b = a.copyWith(spacing: const _DoubleSpacing());

      expect(a.lerp(b, 0.2).spacing.md, 16);
      expect(a.lerp(b, 0.8).spacing.md, 32);
    });
  });
}

class _DoubleSpacing extends ExpressiveSpacing {
  const _DoubleSpacing();

  @override
  double get md => 32;
}
