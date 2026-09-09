import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/theme/app_theme.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';
import 'package:gymflow/src/core/theme/immersivo_tokens.dart';

void main() {
  // Questi due sono testWidgets e non test semplici perche costruire un
  // AppTheme fa risolvere la scala tipografica a GoogleFonts, che senza rete
  // ne font negli asset solleva un'eccezione. L'ambiente widget la tollera,
  // quello unitario no. Cio che si verifica non cambia.
  group('token registrati nel tema', () {
    testWidgets(
      'il tema chiaro espone ImmersivoTokens, non piu ExpressiveTokens',
      (tester) async {
        // Dal redesign Immersivo/Toxic Forest (docs/adr/002) `AppTheme`
        // registra solo `ImmersivoTokens`. `ExpressiveTokens` resta una
        // classe valida — la leggono ancora 5 widget non migrati — ma non
        // arriva piu dal tema: chi la legge vede sempre i suoi default.
        final theme = AppTheme.lightTheme(const Color(0xFFD500F9));
        expect(theme.extension<ExpressiveTokens>(), isNull);
        expect(theme.extension<ImmersivoTokens>(), isNotNull);
      },
    );

    testWidgets(
      'il tema scuro espone ImmersivoTokens, non piu ExpressiveTokens',
      (tester) async {
        final theme = AppTheme.darkTheme(const Color(0xFFD500F9));
        expect(theme.extension<ExpressiveTokens>(), isNull);
        expect(theme.extension<ImmersivoTokens>(), isNotNull);
      },
    );
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

    test('le misure delle miniature crescono in modo monotono', () {
      const s = ExpressiveSizing();
      expect(s.thumbnailSm, lessThan(s.thumbnailMd));
      expect(s.thumbnailMd, lessThan(s.thumbnailLg));
    });

    test('il badge non copre piu di un quarto della miniatura piu piccola', () {
      // Un indicatore che occupa mezza miniatura non e un indicatore: e la
      // miniatura. Il vincolo e sul lato, quindi un quarto dell'area.
      const s = ExpressiveSizing();
      expect(s.badge, lessThanOrEqualTo(s.thumbnailSm / 2));
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

  group('tipografia Immersivo', () {
    // Il tema non espone piu `ExpressiveTokens.typography` (vedi il gruppo
    // sopra): gli stili "protagonisti" di oggi sono qui, in
    // `ImmersivoTokens.typography`, in Anton invece che nella scala
    // "emphasized" di Material 3 Expressive.
    testWidgets('gli stili Anton (display, headline, title) esistono nel tema', (
      tester,
    ) async {
      final t = AppTheme.darkTheme(const Color(0xFFF0C38E))
          .extension<ImmersivoTokens>()!;

      expect(t.typography.display, isNotNull);
      expect(t.typography.headline, isNotNull);
      expect(t.typography.title, isNotNull);
    });

    testWidgets(
      'il titolo Anton ha l altezza e la spaziatura del linguaggio Immersivo, non quelle del base',
      (tester) async {
        // Anton e "un solo peso" (vedi immersivo_tokens.dart): a differenza
        // di ExpressiveTypography, che marcava l'enfasi alzando il
        // `fontWeight`, qui l'enfasi viene dal cambio di famiglia e da
        // altezza/spaziatura scelte apposta — non da un peso piu alto, che
        // Anton non ha.
        final theme = AppTheme.darkTheme(const Color(0xFFF0C38E));
        final t = theme.extension<ImmersivoTokens>()!;
        final base = theme.textTheme.titleLarge!;

        expect(t.typography.title!.letterSpacing, isNot(base.letterSpacing));
        expect(t.typography.title!.height, isNot(base.height));
      },
    );

    testWidgets('il titolo usa Anton, non la famiglia del testo base', (
      tester,
    ) async {
      final theme = AppTheme.darkTheme(const Color(0xFFF0C38E));
      final t = theme.extension<ImmersivoTokens>()!;

      // Qui la differenza e il punto, non un errore: a differenza di
      // ExpressiveTypography (stessa famiglia del corpo, solo piu marcata),
      // Immersivo mescola quattro famiglie con un compito ciascuna — Anton
      // per i titoli, Space Grotesk per il corpo.
      expect(
        t.typography.headline!.fontFamily,
        isNot(theme.textTheme.headlineMedium!.fontFamily),
      );
    });

    testWidgets('gli stili delle metriche usano cifre a larghezza fissa', (
      tester,
    ) async {
      final t = AppTheme.darkTheme(const Color(0xFFF0C38E))
          .extension<ImmersivoTokens>()!;

      for (final style in [
        t.typography.metricLarge,
        t.typography.metricMedium,
        t.typography.metricSmall,
      ]) {
        expect(style, isNotNull);
        expect(
          style!.fontFeatures,
          contains(const FontFeature.tabularFigures()),
          reason: 'i numeri si leggono in colonna: la larghezza deve essere fissa',
        );
      }
    });

    test('i default della tipografia ExpressiveTypography sono nulli, non inventati', () {
      // Senza un TextTheme da cui derivare non si possono costruire stili
      // sensati: meglio nullo che un valore arbitrario che sembra scelto.
      const t = ExpressiveTypography();
      expect(t.displayEmphasized, isNull);
      expect(t.metricLarge, isNull);
    });

    test('copyWith sostituisce un solo stile', () {
      const original = ExpressiveTypography(
        titleEmphasized: TextStyle(fontSize: 20),
        metricLarge: TextStyle(fontSize: 30),
      );
      final copy = original.copyWith(
        titleEmphasized: const TextStyle(fontSize: 24),
      );

      expect(copy.titleEmphasized!.fontSize, 24);
      expect(copy.metricLarge!.fontSize, 30);
    });
  });

}

class _DoubleSpacing extends ExpressiveSpacing {
  const _DoubleSpacing();

  @override
  double get md => 32;

}
