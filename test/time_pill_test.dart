import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/app.dart';
import 'package:gymflow/src/core/theme/expressive_tokens.dart';
import 'package:gymflow/src/services/timer_service.dart';
import 'package:gymflow/src/ui/screens/time_tools_screen.dart';
import 'package:gymflow/src/ui/widgets/timer_overlay.dart';

/// La pillola del tempo: flotta sopra il contenuto e non gli toglie spazio.
///
/// **I test montano `GymFlowShell`, cioe il telaio vero di `app.dart`.** La
/// prima versione di questi test si costruiva una `Column` nel proprio file:
/// sarebbero rimasti verdi anche rimettendo lo `Stack` che copriva il
/// contenuto, cioe proprio il difetto che questa storia chiude. È il difetto
/// n. 3 dell'handoff — provare i pezzi e non il cablaggio fra loro.
///
/// **La pillola flotta, e questo e cambiato dopo la prova sul telefono.** Per un
/// giro ha occupato spazio davvero, spingendo giu il contenuto: era il criterio
/// scritto nel backlog, e visto sullo schermo era peggio del problema che
/// risolveva. Quindi questi test ora sorvegliano l'opposto — che il contenuto
/// **non** si muova — ed e giusto cosi: il criterio veniva da un documento, il
/// giudizio dall'occhio.
///
/// **La superficie di prova ha un bordo di sistema di 40 dp**, perche e con un
/// bordo vero che si vedono i difetti di ingombro.
///
/// **Limite dichiarato**: sono misure di geometria. Che la pillola si legga, e
/// che l'entrata e l'uscita non diano fastidio, resta da confermare sull'APK.
void main() {
  /// Il telaio vero, con un bordo di sistema come su un telefono.
  Widget app(
    ProviderContainer container,
    WidgetTester tester, {
    PreferredSizeWidget? barra,
  }) =>
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
        // `copyWith` e non un `MediaQueryData` costruito da zero: da zero si
        // perde anche la **dimensione** dello schermo, la pillola si posiziona
        // rispetto a una superficie di lato nullo e finisce fuori. Costato un
        // giro di test rossi.
        data: MediaQueryData.fromView(
          tester.view,
        ).copyWith(padding: const EdgeInsets.only(top: 40)),
          child: MaterialApp(
            navigatorKey: navigatorKey,
            theme: ThemeData(extensions: const [ExpressiveTokens()]),
            builder: (context, child) => GymFlowShell(child: child),
            home: Scaffold(
              appBar: barra,
              body: const Center(child: Text('Contenuto', key: Key('c'))),
            ),
          ),
        ),
      );

  ProviderContainer nuovo(WidgetTester tester) {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  testWidgets('compare solo quando cronometro o recupero sono attivi', (
    tester,
  ) async {
    final c = nuovo(tester);
    await tester.pumpWidget(app(c, tester));
    await tester.pumpAndSettle();
    expect(find.byKey(chiavePillola), findsNothing);

    c.read(timerNotifierProvider.notifier).toggleTimer();
    await tester.pumpAndSettle();
    expect(find.byKey(chiavePillola), findsOneWidget);

    c.read(timerNotifierProvider.notifier).resetTimer();
    await tester.pumpAndSettle();
    expect(find.byKey(chiavePillola), findsNothing);

    c.read(timerNotifierProvider.notifier).toggleStopwatch();
    await tester.pumpAndSettle();
    expect(find.byKey(chiavePillola), findsOneWidget);

    c.read(timerNotifierProvider.notifier).resetStopwatch();
    await tester.pumpAndSettle();
  });

  testWidgets('non compare sulla schermata del tempo', (tester) async {
    final c = nuovo(tester);
    c.read(timerNotifierProvider.notifier).toggleTimer();
    await tester.pumpWidget(app(c, tester));
    await tester.pumpAndSettle();
    expect(find.byKey(chiavePillola), findsOneWidget);

    c.read(timerNotifierProvider.notifier).setToolsVisible(true);
    await tester.pumpAndSettle();
    expect(find.byKey(chiavePillola), findsNothing);

    c.read(timerNotifierProvider.notifier).resetTimer();
    await tester.pumpAndSettle();
  });

  testWidgets('quando non c e, non occupa niente', (tester) async {
    // Il difetto trovato in review: la `SafeArea` attorno a tutto impagina un
    // figlio di dimensione zero e si prende comunque la fascia di sistema.
    // Misurato: 40 dp su ogni schermata, sempre, piu i 40 che la `AppBar`
    // aggiunge per conto suo.
    final c = nuovo(tester);
    await tester.pumpWidget(app(c, tester, barra: AppBar(title: const Text('Titolo'))));
    await tester.pumpAndSettle();

    expect(find.byKey(chiavePillola), findsNothing);
    expect(
      tester.getRect(find.byType(AppBar)).top,
      0.0,
      reason: 'a pillola nascosta la barra deve stare dove starebbe senza',
    );
  });

  testWidgets('non sposta il contenuto: ci sta sopra', (tester) async {
    final c = nuovo(tester);
    await tester.pumpWidget(app(c, tester));
    await tester.pumpAndSettle();
    final senza = tester.getRect(find.byKey(const Key('c')));

    c.read(timerNotifierProvider.notifier).toggleTimer();
    await tester.pumpAndSettle();
    final con = tester.getRect(find.byKey(const Key('c')));

    expect(
      con,
      senza,
      reason: 'la pillola flotta: il contenuto sotto resta dov era',
    );

    c.read(timerNotifierProvider.notifier).resetTimer();
    await tester.pumpAndSettle();
  });

  testWidgets('la barra della schermata resta dov era', (tester) async {
    // Il difetto da cui nasce questo test: per un giro la pillola occupava la
    // fascia di sistema **anche da nascosta**, e ogni schermata scendeva di
    // 40 dp per sempre. Ora non deve muovere niente in nessuno dei due stati.
    final c = nuovo(tester);
    await tester.pumpWidget(app(c, tester, barra: AppBar(title: const Text('Titolo'))));
    await tester.pumpAndSettle();
    final barraSenza = tester.getRect(find.byType(AppBar));

    c.read(timerNotifierProvider.notifier).toggleTimer();
    await tester.pumpAndSettle();

    expect(tester.getRect(find.byType(AppBar)), barraSenza);
    expect(barraSenza.top, 0.0);

    c.read(timerNotifierProvider.notifier).resetTimer();
    await tester.pumpAndSettle();
  });

  testWidgets('si puo spostare col dito, e resta nello schermo', (
    tester,
  ) async {
    final c = nuovo(tester);
    c.read(timerNotifierProvider.notifier).toggleTimer();
    await tester.pumpWidget(app(c, tester));
    await tester.pumpAndSettle();

    final prima = tester.getRect(find.byKey(chiavePillola));

    // Trascinandola si sposta, e resta dentro lo schermo: e una pillola
    // flottante, e coprire un pulsante senza poterla spostare sarebbe peggio.
    await tester.drag(find.byKey(chiavePillola), const Offset(0, -200));
    await tester.pumpAndSettle();
    final dopo = tester.getRect(find.byKey(chiavePillola));
    expect(dopo.top, lessThan(prima.top));
    expect(dopo.top, greaterThanOrEqualTo(0.0));

    c.read(timerNotifierProvider.notifier).resetTimer();
    await tester.pumpAndSettle();
  });

  testWidgets('porta i comandi di pausa e azzeramento', (tester) async {
    final c = nuovo(tester);
    final notifier = c.read(timerNotifierProvider.notifier);
    notifier.toggleTimer();
    await tester.pumpWidget(app(c, tester));
    await tester.pumpAndSettle();
    expect(notifier.isTimerRunning, isTrue);

    await tester.tap(find.byIcon(Icons.pause_circle_filled));
    await tester.pumpAndSettle();
    expect(notifier.isTimerRunning, isFalse);

    await tester.tap(find.byIcon(Icons.play_circle_fill));
    await tester.pumpAndSettle();
    expect(notifier.isTimerRunning, isTrue);

    await tester.tap(find.byIcon(Icons.cancel));
    await tester.pumpAndSettle();
    expect(notifier.isTimerRunning, isFalse);
    expect(notifier.timerRemaining, notifier.timerDuration);
  });

  testWidgets('un tocco porta alla schermata del tempo', (tester) async {
    final c = nuovo(tester);
    c.read(timerNotifierProvider.notifier).toggleTimer();
    await tester.pumpWidget(app(c, tester));
    await tester.pumpAndSettle();

    // Sul tempo **dentro la pillola**, non sul primo `Text` dell'albero: da
    // quando la pillola flotta sopra il contenuto, il primo testo dell'albero e
    // quello della schermata sotto. E non al centro della pillola, dove stanno
    // i comandi: toccare li mette in pausa, non naviga.
    await tester.tap(
      find
          .descendant(
            of: find.byKey(chiavePillola),
            matching: find.byType(Text),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(find.byType(TimeToolsScreen, skipOffstage: false), findsOneWidget);

    c.read(timerNotifierProvider.notifier).resetTimer();
    await tester.pumpAndSettle();
  });

  testWidgets('col cronometro e il recupero insieme mostra il recupero', (
    tester,
  ) async {
    final c = nuovo(tester);
    final notifier = c.read(timerNotifierProvider.notifier);
    notifier.toggleStopwatch();
    notifier.setTimerDuration(const Duration(seconds: 45));
    notifier.toggleTimer();
    await tester.pumpWidget(app(c, tester));
    // Un fotogramma solo: `pumpAndSettle` con due ticker in corsa fa scorrere
    // il tempo finto fino a far scadere il recupero, e il numero non e piu
    // quello impostato.
    await tester.pump();

    expect(find.byIcon(Icons.hourglass_bottom), findsOneWidget);
    expect(find.byIcon(Icons.timer), findsNothing);
    // E il numero e quello del recupero, non quello del cronometro.
    expect(find.textContaining('45'), findsOneWidget);

    notifier.resetTimer();
    notifier.resetStopwatch();
    await tester.pump();
  });
}
