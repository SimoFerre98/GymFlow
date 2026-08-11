import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/services/timer_service.dart';

/// Il conto alla rovescia si sente: vibra negli ultimi tre secondi e suona alla
/// fine.
///
/// **Il ticker batte ogni 100 ms.** Il difetto piu probabile qui non e che non
/// vibri: e che vibri **dieci volte al secondo**, cioe trenta colpi invece di
/// tre. Per questo i test contano le vibrazioni invece di limitarsi a
/// verificare che ce ne sia stata almeno una.
///
/// **Limite dichiarato**: `AvvisiTempoDiSistema` — quella vera, che chiama
/// `HapticFeedback` e `SystemSound` — non e provata qui, perche parla con un
/// canale di piattaforma che in un test non esiste. Che il telefono vibri
/// davvero, e che il colpo si senta abbastanza, resta da confermare sull'APK.
class AvvisiFinti implements AvvisiTempo {
  int secondi = 0;
  int scadenze = 0;

  @override
  void secondoFinale() => secondi++;

  @override
  void scaduto() => scadenze++;
}

void main() {
  late ProviderContainer container;
  late TimerNotifier notifier;
  late AvvisiFinti avvisi;

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(timerNotifierProvider.notifier);
    avvisi = AvvisiFinti();
    notifier.avvisi = avvisi;
  });

  tearDown(() => container.dispose());

  test('sopra i tre secondi non vibra', () {
    notifier.setTimerDuration(const Duration(seconds: 10));
    notifier.toggleTimer();
    addTearDown(notifier.resetTimer);

    expect(avvisi.secondi, 0);
  });

  test('negli ultimi tre secondi vibra una volta per secondo', () {
    // Si simula il ticker chiamando la stessa regola che il ticker usa, con i
    // valori che il ticker vedrebbe: il tempo finto dei test non muove
    // `DateTime.now()`, su cui il timer si appoggia.
    for (final millisecondi in [
      3500, 3400, 3100, // terzo secondo: un colpo solo
      2900, 2500, 2100, // secondo
      1900, 1200, 1000, // primo
      900, 400, 100, // zero
    ]) {
      notifier.avvisaSeUltimiSecondi(Duration(milliseconds: millisecondi));
    }

    // Tre colpi: a 2,9 · 1,9 · 0,9 secondi dalla fine. Sono i tre secondi
    // finali, uno per secondo — e non dodici, uno per ogni battito del ticker,
    // che e il difetto che questo test esiste per prendere.
    expect(avvisi.secondi, 3);
  });

  test('tornando sopra la soglia il conto riparte', () {
    notifier.avvisaSeUltimiSecondi(const Duration(milliseconds: 2500));
    expect(avvisi.secondi, 1);

    // Per esempio perche l'utente ha rimesso una durata piu lunga.
    notifier.avvisaSeUltimiSecondi(const Duration(seconds: 30));
    notifier.avvisaSeUltimiSecondi(const Duration(milliseconds: 2500));

    expect(avvisi.secondi, 2, reason: 'il secondo va riavvisato, non ricordato');
  });

  test('alla scadenza suona una volta sola', () {
    notifier.setTimerDuration(const Duration(seconds: 1));
    notifier.toggleTimer();
    notifier.segnalaScadenza();

    expect(avvisi.scadenze, 1);
  });
}
