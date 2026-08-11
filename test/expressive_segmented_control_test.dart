import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/theme/app_theme.dart';
import 'package:gymflow/src/ui/widgets/expressive_segmented_control.dart';

/// Il segmentato del mockup 03: un cursore ambra che scivola sotto l'etichetta
/// scelta.
///
/// **Il difetto che questi test avrebbero preso**: la prima versione leggeva
/// l'altezza dello `Stack` con un `LayoutBuilder` per darla al cursore, ma lo
/// `Stack` prende l'altezza proprio dal `Row` delle etichette — un ciclo che
/// produce un vincolo infinito e fa cadere la schermata. `pumpWidget` da solo
/// lo prende: non serve altro per dimostrarlo, ed e per questo che il primo
/// test qui sotto non fa nient'altro che montare il widget.
void main() {
  // `Scaffold.body` da solo NON basta: gli da un vincolo di altezza **teso**
  // (l'altezza dello schermo), e in quel caso `vincoli.maxHeight` di un
  // `LayoutBuilder` sarebbe un numero finito — il difetto non si vedrebbe.
  //
  // L'uso vero, in `time_tools_screen.dart`, e dentro un `Column` non
  // espanso: e li che l'altezza in arrivo e sciolta (0..infinito), perche il
  // `Column` la lascia decidere al contenuto. Solo cosi il montaggio prende
  // davvero il vincolo infinito che il primo giro di questo widget produceva.
  Widget app({int selezionata = 0}) => MaterialApp(
    theme: AppTheme.darkTheme(const Color(0xFFF0C38E)),
    home: Scaffold(
      body: Column(
        children: [
          ExpressiveSegmentedControl(
            labels: const ['Cronometro', 'Recupero'],
            selectedIndex: selezionata,
            onChanged: (_) {},
          ),
          const Expanded(child: SizedBox()),
        ],
      ),
    ),
  );

  testWidgets('si monta senza vincoli infiniti', (tester) async {
    await tester.pumpWidget(app());
    expect(tester.takeException(), isNull);
  });

  testWidgets('il cursore sta sotto la voce scelta', (tester) async {
    await tester.pumpWidget(app(selezionata: 1));
    await tester.pumpAndSettle();

    final cursore = tester.getRect(find.byType(DecoratedBox).last);
    final destra = tester.getRect(find.text('Recupero'));

    expect(
      cursore.center.dx,
      closeTo(destra.center.dx, 1.0),
      reason: 'con la seconda voce scelta il cursore deve stare sotto di lei',
    );
  });

  testWidgets('toccando una voce si chiama onChanged con il suo indice', (
    tester,
  ) async {
    int? scelto;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme(const Color(0xFFF0C38E)),
        home: Scaffold(
          body: ExpressiveSegmentedControl(
            labels: const ['Cronometro', 'Recupero'],
            selectedIndex: 0,
            onChanged: (i) => scelto = i,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Recupero'));
    expect(scelto, 1);
  });

  testWidgets('la voce scelta si legge sull ambra, l altra no', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    final scheme = AppTheme.darkTheme(const Color(0xFFF0C38E)).colorScheme;

    // `find.ancestor` non basta: `Material` porta un `AnimatedDefaultTextStyle`
    // proprio, quindi «Cronometro» ne ha due sopra di se e non uno solo. Si
    // cerca invece quello **nostro**: quello il cui figlio e esattamente il
    // `Text` con quella parola.
    AnimatedDefaultTextStyle stileDi(String parola) => tester.widget(
      find.byWidgetPredicate(
        (w) =>
            w is AnimatedDefaultTextStyle &&
            w.child is Text &&
            (w.child as Text).data == parola,
      ),
    );

    expect(stileDi('Cronometro').style.color, scheme.onPrimary);
    expect(
      stileDi('Recupero').style.color,
      scheme.onSurface.withValues(alpha: 0.62),
    );
  });
}
