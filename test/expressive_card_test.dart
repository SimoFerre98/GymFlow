import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/theme/app_palette.dart';
import 'package:gymflow/src/core/theme/app_theme.dart';
import 'package:gymflow/src/core/theme/immersivo_tokens.dart';
import 'package:gymflow/src/ui/widgets/expressive_card.dart';

/// Token diversi da quelli veri, per distinguere "legge i token" da "ripete per
/// caso gli stessi numeri". Con i valori di default le due cose sono
/// indistinguibili, ed e esattamente l'errore che questa storia deve evitare.
class _WideSpacing extends ImmersivoSpacing {
  const _WideSpacing();

  @override
  double get lg => 60;

  @override
  double get md => 40;
}

/// Un raggio vistosamente diverso da zero: se la card lo leggesse ancora da un
/// token di forma, l'angolo cambierebbe. Serve a dimostrare che oggi non lo fa
/// piu — vedi il test sotto.
class _RoundedShape extends ImmersivoShape {
  const _RoundedShape();

  @override
  double get radiusLg => 40;
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
      theme: theme ?? AppTheme.darkTheme(AppPalette.accent),
      home: Scaffold(body: child),
    );
  }

  group('i valori vengono dai token', () {
    testWidgets('gli angoli sono vivi: nessun raggio, il confine e un bordo', (
      tester,
    ) async {
      // Immersivo non arrotonda i riquadri (vedi `expressive_card.dart`): il
      // confine si chiude con un filetto su `outline`, non con un raggio letto
      // da un token — quel linguaggio era di Material 3 Expressive.
      await tester.pumpWidget(
        host(const ExpressiveCard(child: Text('contenuto'))),
      );

      final scheme = AppTheme.darkTheme(AppPalette.accent).colorScheme;
      final decoration = decorationOf(tester);
      expect(decoration.borderRadius, isNull);
      expect(decoration.border, Border.all(color: scheme.outline));
    });

    testWidgets(
      'il raggio non reagisce piu a un token di forma: il redesign lo ha fissato',
      (tester) async {
        // Prima di Immersivo il raggio veniva da `ExpressiveShape` ed era
        // reattivo. Oggi `ExpressiveCard` non legge piu alcun token di forma:
        // un valore vistosamente diverso da zero non deve avere effetto.
        await tester.pumpWidget(
          host(
            const ExpressiveCard(child: Text('contenuto')),
            theme: AppTheme.darkTheme(AppPalette.accent).copyWith(
              extensions: const [ImmersivoTokens(shape: _RoundedShape())],
            ),
          ),
        );

        expect(decorationOf(tester).borderRadius, isNull);
      },
    );

    testWidgets('il padding e la spaziatura dei token', (tester) async {
      await tester.pumpWidget(
        host(const ExpressiveCard(child: Text('contenuto'))),
      );

      const tokens = ImmersivoTokens();
      final padding = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(ExpressiveCard),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(padding.padding, EdgeInsets.all(tokens.spacing.md));
    });

    testWidgets('cambiando i token cambia il padding', (tester) async {
      await tester.pumpWidget(
        host(
          const ExpressiveCard(child: Text('contenuto')),
          theme: AppTheme.darkTheme(AppPalette.accent).copyWith(
            extensions: const [ImmersivoTokens(spacing: _WideSpacing())],
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
      expect(padding.padding, const EdgeInsets.all(40));
    });

    testWidgets(
      'non ha piu ombra: il confine e un bordo, non un livello di elevazione',
      (tester) async {
        // Il bagliore sfumato era l'elevazione di Material 3 Expressive;
        // Immersivo chiude ogni riquadro con un filetto, mai con un
        // `boxShadow` (vedi il commento in `expressive_card.dart`).
        await tester.pumpWidget(
          host(const ExpressiveCard(child: Text('contenuto'))),
        );

        expect(decorationOf(tester).boxShadow, isNull);
      },
    );
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

    testWidgets(
      'l onda del tocco non ha un raggio proprio: segue gli angoli vivi della card',
      (tester) async {
        await tester.pumpWidget(
          host(ExpressiveCard(onTap: () {}, child: const Text('contenuto'))),
        );

        final inkWell = tester.widget<InkWell>(find.byType(InkWell));
        // Nessun raggio impostato: l'onda resta rettangolare, come il
        // riquadro che la contiene.
        expect(inkWell.borderRadius, isNull);
      },
    );
  });

  group('i due temi', () {
    testWidgets('nel tema scuro il fondo e la superficie scura', (tester) async {
      final theme = AppTheme.darkTheme(AppPalette.accent);
      await tester.pumpWidget(
        host(const ExpressiveCard(child: Text('contenuto')), theme: theme),
      );

      expect(decorationOf(tester).color, theme.colorScheme.surfaceContainerHigh);
    });

    testWidgets('nel tema chiaro il fondo e quello chiaro', (tester) async {
      final theme = AppTheme.lightTheme(AppPalette.accent);
      await tester.pumpWidget(
        host(const ExpressiveCard(child: Text('contenuto')), theme: theme),
      );

      expect(decorationOf(tester).color, theme.colorScheme.surfaceContainerHigh);
    });

    testWidgets('i due fondi sono davvero diversi', (tester) async {
      // Senza questo, i due test sopra passerebbero anche se il componente
      // ignorasse il tema e usasse sempre lo stesso colore.
      final dark = AppTheme.darkTheme(AppPalette.accent).colorScheme;
      final light = AppTheme.lightTheme(AppPalette.accent).colorScheme;
      expect(dark.surfaceContainerHigh, isNot(light.surfaceContainerHigh));
    });
  });
}
