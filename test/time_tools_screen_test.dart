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
  });
}

/// Wrapper `const` per il primo test, che non ha bisogno del container.
class _AppUnderTest extends StatelessWidget {
  const _AppUnderTest();

  @override
  Widget build(BuildContext context) => _app();
}
