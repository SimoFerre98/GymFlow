import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/services/timer_service.dart';
import 'package:gymflow/src/ui/screens/active_session_screen.dart';

/// Il pulsante del cronometro accanto ai secondi di una serie.
///
/// **La prima versione di questi test riscriveva la logica del pulsante dentro
/// il test** — `final seconds = 0; if (seconds > 0) { ... }` — e poi verificava
/// che il timer fosse fermo. Cosi controllavano il proprio `if`, non la
/// schermata: togliendo dal gestore la guardia sullo zero, o la chiamata che
/// imposta la durata, o quella che controlla se un timer sta gia scorrendo,
/// **restavano tutti e tre verdi**. Misurato.
///
/// Ora chiamano [startSetTimer], che e la logica vera del gestore.
///
/// **Limite dichiarato**: che il pulsante chiami questa funzione lo prova un
/// test sul sorgente, non un tocco vero — `ActiveSessionScreen` non si monta,
/// perche istanzia `FirestoreService` nel proprio `State` (debito di US-008).
/// E che il tempo si veda scorrere resta da confermare sull'APK.
void main() {
  TimerNotifier notifierNuovo() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container.read(timerNotifierProvider.notifier);
  }

  group('startSetTimer', () {
    test('parte sui secondi della serie', () {
      final notifier = notifierNuovo();

      expect(startSetTimer(notifier, 45), isTrue);

      expect(notifier.isTimerRunning, isTrue);
      expect(notifier.timerRemaining, const Duration(seconds: 45));
      // La durata, non solo il residuo: e cio che il timer riprende dopo una
      // pausa, e sbagliarla si vedrebbe solo la seconda volta.
      expect(notifier.timerDuration, const Duration(seconds: 45));
    });

    test('con zero secondi non parte niente', () {
      final notifier = notifierNuovo();
      // Non e zero: il notifier nasce con una durata predefinita. Il punto e
      // che nessuno la tocchi, non che valga un numero in particolare.
      final durataDiPartenza = notifier.timerDuration;

      expect(startSetTimer(notifier, 0), isFalse);

      expect(notifier.isTimerRunning, isFalse);
      expect(notifier.timerDuration, durataDiPartenza);
    });

    test('senza secondi non parte niente', () {
      final notifier = notifierNuovo();

      expect(startSetTimer(notifier, null), isFalse);

      expect(notifier.isTimerRunning, isFalse);
    });

    test('un timer gia in corsa continua, e la serie nuova viene ignorata', () {
      final notifier = notifierNuovo();
      startSetTimer(notifier, 30);

      expect(startSetTimer(notifier, 45), isFalse);

      expect(notifier.isTimerRunning, isTrue);
      expect(notifier.timerDuration, const Duration(seconds: 30));
    });

    test('un timer in pausa viene sostituito da questa serie', () {
      // Non e un caso limite: e la conseguenza dichiarata della scelta di
      // guardare `isTimerRunning`, e va fissata perche si veda se cambia.
      final notifier = notifierNuovo();
      startSetTimer(notifier, 30);
      notifier.toggleTimer(); // pausa
      expect(notifier.isTimerRunning, isFalse);

      expect(startSetTimer(notifier, 45), isTrue);

      expect(notifier.isTimerRunning, isTrue);
      expect(notifier.timerDuration, const Duration(seconds: 45));
    });
  });

  group('il cablaggio con la schermata', () {
    test('il gestore del pulsante chiama startSetTimer', () {
      final sorgente = File(
        'lib/src/ui/screens/active_session_screen.dart',
      ).readAsStringSync();
      expect(sorgente.contains('startSetTimer('), isTrue);
    });

    test('la stringa non dice piu «solo visuale»', () {
      final dizionario = File(
        'lib/src/core/providers/localization_provider.dart',
      ).readAsStringSync();
      expect(dizionario.contains('solo visuale'), isFalse);
      expect(dizionario.contains('visual only'), isFalse);
    });
  });
}
