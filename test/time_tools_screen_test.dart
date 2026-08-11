import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/services/timer_service.dart';
import 'package:gymflow/src/ui/screens/time_tools_screen.dart';

/// Monta la schermata dentro un albero minimo.
///
/// La schermata ha un `Drawer`, quindi serve un `MaterialApp` vero: un
/// `Scaffold` nudo non basta.
Widget _app() => const MaterialApp(home: TimeToolsScreen());

void main() {
  group('TimeToolsScreen', () {
    testWidgets('si apre senza sollevare eccezioni e senza ErrorWidget',
        (tester) async {
      // E il test che mancava. Il difetto era deterministico:
      // `didChangeDependencies` modificava un provider al primo build, quindi
      // chiunque avesse montato questa schermata una volta l'avrebbe visto.
      await tester.pumpWidget(const ProviderScope(child: _AppUnderTest()));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);
      expect(find.byType(TimeToolsScreen), findsOneWidget);
    });

    testWidgets('entrando nasconde e uscendo mostra l overlay flottante',
        (tester) async {
      final container = ProviderContainer();

      // Prima di aprire la schermata l'overlay e visibile.
      expect(
        container.read(timerNotifierProvider).isToolsVisible,
        isFalse,
        reason: 'lo stato iniziale non considera gli strumenti a schermo',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _app(),
        ),
      );
      await tester.pump();

      expect(
        container.read(timerNotifierProvider).isToolsVisible,
        isTrue,
        reason: 'dentro la schermata l overlay non deve sovrapporsi',
      );

      // Si esce: la schermata viene smontata.
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold()),
        ),
      );
      // Il microtask di `dispose` gira qui.
      await tester.pump();

      expect(
        container.read(timerNotifierProvider).isToolsVisible,
        isFalse,
        reason: 'uscendo l overlay flottante deve tornare disponibile',
      );

      container.dispose();
    });

    testWidgets('aprire e chiudere la schermata non azzera il cronometro',
        (tester) async {
      final container = ProviderContainer();
      final notifier = container.read(timerNotifierProvider.notifier);

      // Lo stato si prepara con la durata del conto alla rovescia e con il
      // cronometro in corsa, non col tempo trascorso: il cronometro misura con
      // `DateTime.now()`, che l'orologio finto dei test non muove. Quindi
      // `stopwatchElapsed` resta a zero, e `lapStopwatch` rifiuta a tempo zero.
      // La durata impostata e lo stato «in corsa» non dipendono dall'orologio e
      // andrebbero persi allo stesso modo se il notifier venisse ricreato.
      notifier.setTimerDuration(const Duration(minutes: 3));
      notifier.toggleStopwatch();

      final prima = container.read(timerNotifierProvider);
      expect(prima.timerDuration, const Duration(minutes: 3));
      expect(prima.isStopwatchRunning, isTrue);

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: _app()),
      );
      await tester.pump();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold()),
        ),
      );
      await tester.pump();

      // Lo stato del cronometro vive nel notifier `keepAlive`: la schermata che
      // va e viene non lo tocca. E la regressione che farebbe piu danno, perche
      // perderebbe un allenamento cronometrato.
      final dopo = container.read(timerNotifierProvider);
      expect(dopo.timerDuration, const Duration(minutes: 3));
      expect(dopo.isStopwatchRunning, isTrue);

      // Smontato dentro il corpo e non in un `addTearDown`: qui il cronometro
      // e in corsa, quindi da US-013 il ticker **c'e**, e `testWidgets`
      // fallisce se al termine resta un timer pendente. Nei test dove nulla
      // scorre il ticker non parte e questo giro non servirebbe.
      container.dispose();
    });

    testWidgets('toccando Avvia la schermata si ridisegna sullo stato nuovo',
        (tester) async {
      // E il test che mancava a US-075. Quelli che c'erano provavano il
      // notifier — che era corretto — e che la schermata si aprisse senza
      // eccezioni. Nessuno guardava cosa viene **disegnato**, e con `ref.read`
      // al posto di `ref.watch` le viste non si iscrivevano a niente: i tasti
      // funzionavano, lo stato cambiava, lo schermo restava fermo sul primo
      // frame. Da qui il «tocco un tasto e non succede nulla».
      //
      // ⚠️ Quello che questo test **non** puo verificare e che le cifre
      // avanzino: il cronometro misura con `DateTime.now()`, che l'orologio
      // finto dei test non muove, quindi `stopwatchElapsed` resta a zero anche
      // battendo il ticker. Lo dice gia il test qui sopra. Le etichette dei
      // tasti invece vengono da `isStopwatchRunning`, che cambia al tocco e non
      // dipende dall'orologio: se la vista non si iscrive, restano quelle di
      // prima. E la stessa iscrizione che muove le cifre sul telefono.
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const _AppUnderTest(),
        ),
      );
      await tester.pump();

      // I comandi sono icone da quando la schermata segue il mockup 03: si
      // cercano per **etichetta accessibile**, che e cio che significano, e non
      // per icona — se un giorno la freccia cambia disegno il test non deve
      // rompersi, se cambia significato si.
      //
      // La lingua predefinita del progetto e l'italiano.
      expect(find.bySemanticsLabel('Avvia'), findsOneWidget);
      expect(find.bySemanticsLabel('Pausa'), findsNothing);

      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump(const Duration(milliseconds: 350));

      expect(
        find.bySemanticsLabel('Pausa'),
        findsOneWidget,
        reason: 'partito il cronometro, il pulsante grande diventa Pausa',
      );
      expect(
        find.bySemanticsLabel('Avvia'),
        findsNothing,
        reason: 'e non resta anche quello di prima',
      );
      expect(
        tester.widget<IconButton>(
          find.ancestor(
            of: find.byIcon(Icons.flag_outlined),
            matching: find.byType(IconButton),
          ),
        ).onPressed,
        isNotNull,
        reason: 'e il giro si puo segnare solo mentre scorre',
      );

      // Si ferma il ticker, o `testWidgets` protesta per un timer pendente.
      container.read(timerNotifierProvider.notifier).toggleStopwatch();
      await tester.pump();
      container.dispose();
    });
  });
}

/// Wrapper `const` per il primo test, che non ha bisogno del container.
class _AppUnderTest extends StatelessWidget {
  const _AppUnderTest();

  @override
  Widget build(BuildContext context) => _app();
}
