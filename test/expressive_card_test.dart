import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/theme/app_palette.dart';
import 'package:gymflow/src/core/theme/app_theme.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';
import 'package:gymflow/src/ui/widgets/expressive_card.dart';

/// Token diversi da quelli veri, per distinguere "legge i token" da "ripete per
/// caso gli stessi numeri". Con i valori di default le due cose sono
/// indistinguibili, ed e esattamente l'errore che questa storia deve evitare.
class _WideSpacing extends ExpressiveSpacing {
  const _WideSpacing();

  @override
  double get lg => 60;

  @override
  double get md => 40;
}

class _SquareShape extends ExpressiveShape {
  const _SquareShape();

  @override
  double get radiusLg => 0;
}

BoxDecoration decorationOf(WidgetTester tester) {
  return tester
          .widget<DecoratedBox>(
            find
                .descendant(
                  of: find.byType(ExpressiveCard),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          )
          .decoration
      as BoxDecoration;
}

void main() {
  Widget host(Widget child, {ThemeData? theme}) {
    return MaterialApp(
      theme: theme ?? AppTheme.darkTheme(AppPalette.amber),
      home: Scaffold(body: child),
    );
  }

  group('i valori vengono dai token', () {
    testWidgets('il raggio e quello dei token, non un numero scritto', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const ExpressiveCard(child: Text('contenuto'))),
      );

      const tokens = ExpressiveTokens();
      expect(decorationOf(tester).borderRadius, tokens.shape.cornerLg);
    });

    testWidgets('cambiando i token cambia il raggio disegnato', (tester) async {
      // La prova che il widget **legge** i token invece di ripeterne i valori:
      // con `BorderRadius.circular(24)` scritto a mano, questo test fallisce.
      await tester.pumpWidget(
        host(
          const ExpressiveCard(child: Text('contenuto')),
          theme: AppTheme.darkTheme(AppPalette.amber).copyWith(
            extensions: const [ExpressiveTokens(shape: _SquareShape())],
          ),
        ),
      );

      expect(decorationOf(tester).borderRadius, BorderRadius.circular(0));
    });

    testWidgets('il padding e la spaziatura dei token', (tester) async {
      await tester.pumpWidget(
        host(const ExpressiveCard(child: Text('contenuto'))),
      );

      const tokens = ExpressiveTokens();
      final padding = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(ExpressiveCard),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(padding.padding, EdgeInsets.all(tokens.spacing.lg));
    });

    testWidgets('cambiando i token cambia il padding', (tester) async {
      await tester.pumpWidget(
        host(
          const ExpressiveCard(child: Text('contenuto')),
          theme: AppTheme.darkTheme(AppPalette.amber).copyWith(
            extensions: const [ExpressiveTokens(spacing: _WideSpacing())],
          ),
        ),
      );

      final padding = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(ExpressiveCard),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(padding.padding, const EdgeInsets.all(60));
    });

    testWidgets('l ombra e quella dei token, e non e nera per sempre', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const ExpressiveCard(child: Text('contenuto'))),
      );

      final scheme = AppTheme.darkTheme(AppPalette.amber).colorScheme;
      const tokens = ExpressiveTokens();
      expect(
        decorationOf(tester).boxShadow,
        tokens.elevation.level2(scheme.shadow),
      );
    });
  });

  group('titolo', () {
    testWidgets('senza titolo non occupa spazio', (tester) async {
      await tester.pumpWidget(
        host(const ExpressiveCard(child: Text('contenuto'))),
      );

      expect(find.text('contenuto'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('con titolo compaiono entrambi', (tester) async {
      await tester.pumpWidget(
        host(
          const ExpressiveCard(title: 'Attivita', child: Text('contenuto')),
        ),
      );

      expect(find.text('Attivita'), findsOneWidget);
      expect(find.text('contenuto'), findsOneWidget);
    });

    testWidgets('il titolo prende uno stile del tema, non una misura', (
      tester,
    ) async {
      // Lo stile atteso si legge **dentro l'albero**: fuori, il `TextTheme` non
      // e ancora stato fuso con la tipografia di default e le dimensioni sono
      // nulle. Confrontarlo da fuori proverebbe una cosa diversa.
      TextStyle? ambient;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              ambient = Theme.of(context).textTheme.titleMedium;
              return const ExpressiveCard(
                title: 'Attivita',
                child: Text('contenuto'),
              );
            },
          ),
        ),
      );

      final style = tester.widget<Text>(find.text('Attivita')).style;
      expect(style?.fontSize, ambient?.fontSize);
      expect(style?.fontFamily, ambient?.fontFamily);
      expect(style?.fontWeight, FontWeight.bold);
    });
  });

  group('tocco', () {
    testWidgets('senza azione la card non reagisce', (tester) async {
      await tester.pumpWidget(
        host(const ExpressiveCard(child: Text('contenuto'))),
      );

      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.onTap, isNull);
    });

    testWidgets('con azione il tocco arriva', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        host(
          ExpressiveCard(
            onTap: () => tapped++,
            child: const Text('contenuto'),
          ),
        ),
      );

      await tester.tap(find.text('contenuto'));
      await tester.pump();

      expect(tapped, 1);
    });

    testWidgets('l onda del tocco segue gli angoli della card', (tester) async {
      await tester.pumpWidget(
        host(ExpressiveCard(onTap: () {}, child: const Text('contenuto'))),
      );

      const tokens = ExpressiveTokens();
      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.borderRadius, tokens.shape.cornerLg);
    });
  });

  group('i due temi', () {
    testWidgets('nel tema scuro il fondo e la superficie scura', (tester) async {
      final theme = AppTheme.darkTheme(AppPalette.amber);
      await tester.pumpWidget(
        host(const ExpressiveCard(child: Text('contenuto')), theme: theme),
      );

      expect(decorationOf(tester).color, theme.colorScheme.surfaceContainer);
    });

    testWidgets('nel tema chiaro il fondo e quello chiaro', (tester) async {
      final theme = AppTheme.lightTheme(AppPalette.amber);
      await tester.pumpWidget(
        host(const ExpressiveCard(child: Text('contenuto')), theme: theme),
      );

      expect(decorationOf(tester).color, theme.colorScheme.surfaceContainer);
    });

    testWidgets('i due fondi sono davvero diversi', (tester) async {
      // Senza questo, i due test sopra passerebbero anche se il componente
      // ignorasse il tema e usasse sempre lo stesso colore.
      final dark = AppTheme.darkTheme(AppPalette.amber).colorScheme;
      final light = AppTheme.lightTheme(AppPalette.amber).colorScheme;
      expect(dark.surfaceContainer, isNot(light.surfaceContainer));
    });
  });
}
