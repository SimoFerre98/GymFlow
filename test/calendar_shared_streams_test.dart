import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';

/// Perche il calendario non mostrava gli allenamenti appena programmati.
///
/// Il calendario unisce quattro stream con `Rx.combineLatest4`: sessioni
/// proprie, allenamenti programmati propri, e i due **condivisi**. Le query dei
/// condivisi leggono i documenti utente (`users where calendarSharedWith
/// arrayContains`), e le regole pubblicate da US-018 le negano — per scelta,
/// perche la condivisione fra amici va rifatta con US-080.
///
/// Il difetto non era la negazione: era cosa ne faceva il calendario.
void main() {
  group('combineLatest e un ingresso che va in errore', () {
    /// Gli altri tre ingressi, che funzionano.
    Stream<int> funzionante(int valore) => Stream.value(valore);

    test('senza difese, un ingresso in errore spegne la vista intera',
        () async {
      // E il difetto, scritto come test perche non torni: l'ingresso negato
      // solleva **senza aver mai emesso**, e `combineLatest` non emette finche
      // ogni ingresso non ha emesso almeno una volta. Risultato: zero
      // emissioni, e il calendario non mostra niente — nemmeno gli allenamenti
      // propri, che erano leggibilissimi.
      final negato = Stream<int>.error(
        Exception('PERMISSION_DENIED: Missing or insufficient permissions'),
      );

      final unite = Rx.combineLatest4<int, int, int, int, int>(
        funzionante(1),
        funzionante(2),
        negato,
        funzionante(4),
        (a, b, c, d) => a + b + c + d,
      );

      final emissioni = <int>[];
      await unite.listen(emissioni.add, onError: (_) {}).asFuture<void>().catchError((_) {});

      expect(
        emissioni,
        isEmpty,
        reason: 'e la prova del difetto: nessuna emissione, quindi niente a schermo',
      );
    });

    test('con onErrorReturnWith, la vista sopravvive e mostra il resto',
        () async {
      // La correzione: l'errore non si propaga, si registra e si emette una
      // lista vuota — che e la verita, di condivisi non ce ne sono.
      final negatoMaGentile = Stream<int>.error(
        Exception('PERMISSION_DENIED'),
      ).onErrorReturnWith((_, _) => 0);

      final unite = Rx.combineLatest4<int, int, int, int, int>(
        funzionante(1),
        funzionante(2),
        negatoMaGentile,
        funzionante(4),
        (a, b, c, d) => a + b + c + d,
      );

      final emissioni = await unite.toList();

      expect(
        emissioni,
        isNotEmpty,
        reason: 'la vista deve continuare a mostrare gli eventi propri',
      );
      expect(emissioni.last, 7, reason: '1 + 2 + 0 + 4');
    });
  });

  group('Verifica sorgente — i due stream condivisi si difendono', () {
    final sorgente =
        File('lib/src/services/firestore_service.dart').readAsStringSync();

    /// Il corpo di un metodo, dalla firma alla firma successiva.
    String corpoDi(String firma) {
      final inizio = sorgente.indexOf(firma);
      expect(inizio, greaterThan(-1), reason: '$firma non trovata');
      final dopo = sorgente.indexOf('\n  Stream<', inizio + firma.length);
      return sorgente.substring(
        inizio,
        dopo == -1 ? sorgente.length : dopo,
      );
    }

    for (final firma in const [
      'Stream<List<WorkoutSession>> getSharedSessions',
      'Stream<List<ScheduledWorkout>> getSharedScheduledWorkouts',
    ]) {
      test('$firma non lascia sfuggire l errore', () {
        expect(
          corpoDi(firma),
          contains('onErrorReturnWith'),
          reason: 'un errore qui spegne il calendario intero: '
              'va registrato e trasformato in una lista vuota',
        );
      });
    }
  });
}
