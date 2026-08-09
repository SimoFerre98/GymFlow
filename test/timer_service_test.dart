import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/services/timer_service.dart';

void main() {
  group('TimerNotifier — il ticker batte solo quando serve', () {
    test('leggere il provider non avvia niente', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(timerNotifierProvider.notifier);

      // E il criterio centrale della storia. Va osservato: appoggiarsi al fatto
      // che `testWidgets` protesti per i timer pendenti non lo dimostra, perche
      // smontare il container cancella il ticker comunque.
      expect(notifier.isTickerActive, isFalse);
    });

    test('il cronometro accende e spegne il ticker', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(timerNotifierProvider.notifier);

      notifier.toggleStopwatch();
      expect(notifier.isTickerActive, isTrue);

      notifier.toggleStopwatch();
      expect(notifier.isTickerActive, isFalse);
    });

    test('azzerare il cronometro spegne il ticker', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(timerNotifierProvider.notifier);

      notifier.toggleStopwatch();
      expect(notifier.isTickerActive, isTrue);

      notifier.resetStopwatch();
      expect(notifier.isTickerActive, isFalse);
    });

    test('il conto alla rovescia accende e spegne il ticker', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(timerNotifierProvider.notifier);

      notifier.setTimerDuration(const Duration(minutes: 1));
      expect(
        notifier.isTickerActive,
        isFalse,
        reason: 'impostare una durata non e farla scorrere',
      );

      notifier.toggleTimer();
      expect(notifier.isTickerActive, isTrue);

      notifier.resetTimer();
      expect(notifier.isTickerActive, isFalse);
    });

    test('con entrambi in corsa, fermarne uno non spegne il ticker', () {
      // E il percorso che una gestione sbagliata rompe: fermare il cronometro
      // mentre il conto alla rovescia scorre ancora spegnerebbe il ticker, e il
      // conto alla rovescia si fermerebbe a schermo senza essere in pausa.
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(timerNotifierProvider.notifier);

      notifier.setTimerDuration(const Duration(minutes: 1));
      notifier.toggleTimer();
      notifier.toggleStopwatch();
      expect(notifier.isTickerActive, isTrue);

      notifier.toggleStopwatch();
      expect(
        notifier.isTickerActive,
        isTrue,
        reason: 'il conto alla rovescia sta ancora scorrendo',
      );

      notifier.toggleTimer();
      expect(notifier.isTickerActive, isFalse);
    });

    test('smontare il container ferma il ticker', () {
      final container = ProviderContainer();
      final notifier = container.read(timerNotifierProvider.notifier);

      notifier.toggleStopwatch();
      expect(notifier.isTickerActive, isTrue);

      container.dispose();
      expect(notifier.isTickerActive, isFalse);
    });

    test('la frequenza e coerente con i decimi mostrati a schermo', () {
      expect(kTickerInterval, const Duration(milliseconds: 100));
    });
  });

  group('TimerNotifier — il tempo non dipende dai tick', () {
    test('in pausa il tempo e quello vero, non quello dell ultimo tick',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(timerNotifierProvider.notifier);

      notifier.toggleStopwatch();
      // Un'attesa vera e breve, e non microsecondi: su Windows due
      // `DateTime.now()` consecutivi possono cadere nello stesso istante, e il
      // test sarebbe capriccioso. 20 ms sono meno di un tick da 100.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      notifier.toggleStopwatch();

      // Nessun tick ha girato: il ticker batte ogni 100 ms e ne sono passati
      // 20. Se il tempo mostrato venisse dai tick sarebbe rimasto esattamente
      // zero.
      //
      // Questo dimostra due cose in una: che il valore e calcolato da
      // `DateTime.now()` — quindi il tempo resta corretto anche se l'app e
      // stata in background e nessun tick ha girato — e che mettendo in pausa
      // il valore mostrato si allinea al tempo vero invece di restare indietro
      // di un tick, che a 100 ms sarebbe un decimo intero, cioe la cifra piu
      // fine che lo schermo mostra.
      expect(
        container.read(timerNotifierProvider).stopwatchElapsed,
        greaterThan(Duration.zero),
      );
    });
  });
}
