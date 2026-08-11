import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/services/timer_notification_channel.dart';
import 'package:gymflow/src/services/timer_service.dart';

/// Il recupero fuori dall'app: US-053.
///
/// `TimerNotifier` non parla mai direttamente col servizio nativo in questi
/// test — parlerebbe con un canale di piattaforma che qui non esiste — parla
/// con `FakeCanale`, che registra le chiamate e restituisce lo stato che il
/// test decide.
///
/// **Limite dichiarato**: questi test provano che `TimerNotifier` chiama il
/// canale al momento giusto, con i valori giusti. Non provano che il servizio
/// Android faccia quel che deve, che la notifica compaia, o che il permesso
/// venga davvero chiesto con la schermata che ne spiega il motivo — quella
/// schermata non esiste ancora, ed e dichiarato anche nel codice.
class FakeCanale implements TimerNotificationChannel {
  DateTime? ultimoAvvio;
  Duration? ultimaPausa;
  int fermate = 0;
  StatoServizioTimer? statoDaRestituire;

  @override
  Future<void> avvia(DateTime orarioFine) async {
    ultimoAvvio = orarioFine;
  }

  @override
  Future<void> metteInPausa(Duration restante) async {
    ultimaPausa = restante;
  }

  @override
  Future<void> ferma() async {
    fermate++;
  }

  @override
  Future<StatoServizioTimer?> leggiStato() async => statoDaRestituire;
}

void main() {
  late ProviderContainer container;
  late TimerNotifier notifier;
  late FakeCanale canale;

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(timerNotifierProvider.notifier);
    canale = FakeCanale();
    notifier.servizioTimer = canale;
    notifier.richiediPermessoNotifiche = () async => true;
  });

  tearDown(() {
    notifier.resetTimer();
    container.dispose();
  });

  group('avvio e pausa', () {
    test('avviando il recupero, il canale riceve l orario di fine', () async {
      notifier.setTimerDuration(const Duration(seconds: 90));
      notifier.toggleTimer();
      // `toggleTimer` non aspetta il canale: chiede il permesso e avvia il
      // servizio senza bloccare l'interfaccia, quindi qui si aspetta che
      // quella catena di `await` interna arrivi in fondo prima di guardare
      // cosa e successo.
      await Future<void>.delayed(Duration.zero);

      expect(canale.ultimoAvvio, isNotNull);
      expect(
        canale.ultimoAvvio!.difference(DateTime.now()).inSeconds,
        closeTo(90, 1),
      );
    });

    test('senza il permesso, il canale non viene avviato', () async {
      notifier.richiediPermessoNotifiche = () async => false;
      notifier.setTimerDuration(const Duration(seconds: 90));
      notifier.toggleTimer();
      await Future<void>.delayed(Duration.zero);

      expect(
        canale.ultimoAvvio,
        isNull,
        reason: 'un servizio che nessuno vedrebbe non vale la batteria che costa',
      );
      expect(
        notifier.isTimerRunning,
        isTrue,
        reason: 'il permesso negato non deve fermare il timer dentro l app',
      );
    });

    test('se il permesso solleva un eccezione, il timer funziona comunque', () {
      notifier.richiediPermessoNotifiche = () async =>
          throw Exception('canale di piattaforma assente');
      notifier.setTimerDuration(const Duration(seconds: 30));

      expect(() => notifier.toggleTimer(), returnsNormally);
      expect(notifier.isTimerRunning, isTrue);
    });

    test('mettendo in pausa, il canale riceve il tempo restante', () {
      notifier.setTimerDuration(const Duration(seconds: 45));
      notifier.toggleTimer();
      notifier.toggleTimer(); // pausa

      expect(canale.ultimaPausa, const Duration(seconds: 45));
    });
  });

  group('arresto', () {
    test('azzerando il timer, il canale viene fermato', () {
      notifier.setTimerDuration(const Duration(seconds: 20));
      notifier.toggleTimer();
      notifier.resetTimer();

      expect(canale.fermate, greaterThanOrEqualTo(1));
    });

    test('alla scadenza naturale, il canale viene fermato', () async {
      // Un tempo vero e non simulato: la scoperta della scadenza vive dentro
      // il ticker privato, e l'unico modo onesto di provarla e lasciare che
      // il tempo vero passi e il ticker (100 ms) se ne accorga da solo.
      notifier.setTimerDuration(const Duration(milliseconds: 50));
      notifier.toggleTimer();

      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(notifier.isTimerRunning, isFalse);
      expect(canale.fermate, greaterThanOrEqualTo(1));
    });
  });

  group('riconciliazione al ritorno in primo piano', () {
    test('se non c e un timer in corsa, non legge il canale', () async {
      await notifier.riconciliaConIlServizio();
      // Nessuna eccezione, e lo stato resta quello di partenza: e il caso
      // piu comune — l'app si apre e non c e nessun recupero in corso.
      expect(notifier.isTimerRunning, isFalse);
    });

    test('se il servizio dice che il tempo e scaduto, si tratta come scaduto', () async {
      notifier.setTimerDuration(const Duration(seconds: 10));
      notifier.toggleTimer();

      canale.statoDaRestituire = StatoServizioTimer(
        orarioFine: DateTime.now().subtract(const Duration(seconds: 5)),
        inPausa: false,
        restanteAllaPausa: Duration.zero,
      );

      await notifier.riconciliaConIlServizio();

      expect(notifier.isTimerRunning, isFalse);
      expect(notifier.timerRemaining, Duration.zero);
    });

    test('se il servizio dice in pausa, il notifier si allinea in pausa', () async {
      notifier.setTimerDuration(const Duration(seconds: 60));
      notifier.toggleTimer();

      canale.statoDaRestituire = StatoServizioTimer(
        orarioFine: DateTime.now().add(const Duration(seconds: 40)),
        inPausa: true,
        restanteAllaPausa: const Duration(seconds: 40),
      );

      await notifier.riconciliaConIlServizio();

      expect(notifier.isTimerRunning, isFalse);
      expect(notifier.timerRemaining, const Duration(seconds: 40));
    });

    test('se il servizio dice ancora in corsa, il resto si aggiorna', () async {
      notifier.setTimerDuration(const Duration(seconds: 60));
      notifier.toggleTimer();

      canale.statoDaRestituire = StatoServizioTimer(
        orarioFine: DateTime.now().add(const Duration(seconds: 12)),
        inPausa: false,
        restanteAllaPausa: Duration.zero,
      );

      await notifier.riconciliaConIlServizio();

      expect(notifier.isTimerRunning, isTrue);
      expect(notifier.timerRemaining.inSeconds, closeTo(12, 1));
    });
  });
}
