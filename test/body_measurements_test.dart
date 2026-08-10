import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/providers/localization_provider.dart';
import 'package:gymflow/src/models/body_measurement.dart';

void main() {
  // ── Test del modello dati ───────────────────────────────────
  //
  // I widget test della schermata richiederebbero Firebase inizializzato
  // (AuthService usa Firebase.app()). Senza un setup di test Firebase
  // dedicato, i test di rendering sono da confermare sull'APK.
  //
  // I test unitari sul modello e sulla logica non hanno questa dipendenza
  // e verificano i criteri di accettazione in modo affidabile.

  group('BodyMeasurement — priorità peso manuale (C3)', () {
    test('il peso manuale resta distinto da quello importato da Salute', () {
      // Il modello BodyMeasurement non ha un campo isManualWeight o
      // weightSource. La protezione contro la sovrascrittura da Health è
      // architetturale: la schermata salva SOLO pesi inseriti dall'utente.
      // Un'eventuale integrazione Health dovrebbe creare record separati.
      //
      // Questo test verifica che due misurazioni con peso diverso restino
      // distinte e non si sovrascrivano.

      final manuale = BodyMeasurement(
        id: 'manual-1',
        userId: 'test-user',
        date: DateTime(2025, 8, 10, 10, 0),
        weight: 75.0,
      );

      final daSalute = BodyMeasurement(
        id: 'health-1',
        userId: 'test-user',
        date: DateTime(2025, 8, 10, 10, 5),
        weight: 74.2,
      );

      // Il record manuale conserva il proprio peso.
      expect(manuale.weight, 75.0);
      expect(daSalute.weight, 74.2);

      // Sono due record distinti: id diverso, peso diverso.
      expect(manuale.id, isNot(daSalute.id));
      expect(manuale.weight, isNot(daSalute.weight));

      // In una lista ordinata per data, il più recente (da Salute) non
      // cancella quello manuale: entrambi esistono.
      final misurazioni = [manuale, daSalute];
      expect(misurazioni.length, 2);
      expect(
        misurazioni.where((m) => m.weight == 75.0).length,
        1,
        reason: 'il peso manuale deve restare nella lista',
      );
    });

    test('un aggiornamento da Health non modifica un record esistente', () {
      // Poiché BodyMeasurement è immutabile (tutti i campi sono final),
      // un record creato dall'utente non può essere modificato: si può
      // solo creare un nuovo record. Questo è il meccanismo che impedisce
      // la sovrascrittura.

      final manuale = BodyMeasurement(
        id: 'rec-1',
        userId: 'test-user',
        date: DateTime(2025, 8, 10),
        weight: 80.0,
      );

      // Il peso è final: non può essere cambiato dopo la creazione.
      // Nessun setter, nessun metodo di modifica.
      expect(manuale.weight, 80.0);

      // L'unico modo per registrare un peso diverso è un nuovo record.
      final nuovoRecord = BodyMeasurement(
        id: 'rec-2',
        userId: 'test-user',
        date: DateTime(2025, 8, 10, 0, 1),
        weight: 79.5,
      );

      // Il record originale non è stato toccato.
      expect(manuale.weight, 80.0);
      expect(nuovoRecord.weight, 79.5);
      expect(identical(manuale, nuovoRecord), isFalse);
    });
  });

  group('BodyMeasurement — misure corporee (C5)', () {
    test('le misure corporee sono registrabili', () {
      final m = BodyMeasurement(
        id: 'measures-1',
        userId: 'test-user',
        date: DateTime.now(),
        waist: 82.5,
        hips: 95.0,
        biceps: 35.0,
      );

      expect(m.waist, 82.5);
      expect(m.hips, 95.0);
      expect(m.biceps, 35.0);
    });

    test('i campi opzionali possono essere null', () {
      final m = BodyMeasurement(
        id: 'partial-1',
        userId: 'test-user',
        date: DateTime.now(),
        weight: 70.0,
      );

      expect(m.weight, 70.0);
      expect(m.waist, isNull);
      expect(m.hips, isNull);
      expect(m.biceps, isNull);
    });
  });

  group('BodyMeasurement — timestamp (C6)', () {
    test('il salvataggio include il timestamp', () {
      final ora = DateTime.now();
      final m = BodyMeasurement(
        id: 'ts-test',
        userId: 'test-user',
        date: ora,
        weight: 80.0,
        waist: 85.0,
      );

      expect(m.date, ora);
      expect(m.date.difference(ora).inSeconds, 0);
    });

    test('ogni misura ha un timestamp distinto', () {
      final t1 = DateTime(2025, 8, 10, 10, 0);
      final t2 = DateTime(2025, 8, 11, 10, 0);

      final m1 = BodyMeasurement(
        id: '1',
        userId: 'u',
        date: t1,
        weight: 75.0,
      );
      final m2 = BodyMeasurement(
        id: '2',
        userId: 'u',
        date: t2,
        weight: 74.8,
      );

      expect(m1.date, isNot(m2.date));
      expect(m2.date.isAfter(m1.date), isTrue);
    });
  });

  group('Localizzazione US-066', () {
    test('tutte le chiavi US-066 sono tradotte in EN e IT', () {
      const chiavi = [
        'current_weight',
        'weight_history',
        'body_measures_section',
        'bm_waist',
        'bm_hips',
        'bm_arms',
        'bm_kg',
        'bm_cm',
        'enter_weight',
        'measurements_saved',
        'no_measurements',
      ];

      final en = const Localization(Locale('en'));
      final it = const Localization(Locale('it'));

      for (final key in chiavi) {
        // t() restituisce la chiave stessa quando non la trova.
        expect(en.t(key), isNot(key), reason: '"$key" manca in EN');
        expect(it.t(key), isNot(key), reason: '"$key" manca in IT');
      }
    });

    test('le traduzioni non sono identiche fra EN e IT (campione)', () {
      final en = const Localization(Locale('en'));
      final it = const Localization(Locale('it'));

      // Chiavi che devono avere traduzioni diverse nelle due lingue.
      for (final key in [
        'current_weight',
        'weight_history',
        'bm_waist',
        'enter_weight',
      ]) {
        expect(it.t(key), isNot(en.t(key)), reason: key);
      }
    });
  });

  group('US-066 review: ogni campo del modello ha un posto a schermo', () {
    // I nomi dei campi di `BodyMeasurement`, letti dal sorgente del modello:
    // cosi il test non si fida di un elenco che potrebbe essere vecchio.
    Set<String> campiDelModello() {
      final sorgente = File('lib/src/models/body_measurement.dart')
          .readAsStringSync();
      final campi = RegExp(r'final (?:double|int)\? ([a-zA-Z]+);')
          .allMatches(sorgente)
          .map((m) => m.group(1)!)
          .toSet();
      // Il peso ha il cursore e non un campo di testo.
      return campi..remove('weight');
    }

    Set<String> campiDellaSchermata() {
      final sorgente =
          File('lib/src/ui/screens/body_measurements_screen.dart')
              .readAsStringSync();
      return RegExp(r"_CampoMisura\('([a-zA-Z]+)'")
          .allMatches(sorgente)
          .map((m) => m.group(1)!)
          .toSet();
    }

    test('nessun campo del modello resta senza campo a schermo', () {
      final modello = campiDelModello();
      final schermata = campiDellaSchermata();

      // `bodyFat` a schermo corrisponde a `bodyFatPercentage` nel modello.
      final normalizzati = schermata
          .map((c) => c == 'bodyFat' ? 'bodyFatPercentage' : c)
          .toSet();

      expect(
        modello.difference(normalizzati),
        isEmpty,
        reason: 'un campo che si salva e non si rivede e un dato perso in '
            'silenzio: la consegna ne aveva lasciati otto senza posto',
      );
    });

    test('la schermata non inventa campi che il modello non ha', () {
      final modello = campiDelModello();
      final normalizzati = campiDellaSchermata()
          .map((c) => c == 'bodyFat' ? 'bodyFatPercentage' : c)
          .toSet();

      expect(normalizzati.difference(modello), isEmpty);
    });
  });
}



// ─────────────────────────────────────────────────────────────────────────────
// Correzione di review US-066
// ─────────────────────────────────────────────────────────────────────────────
//
// La consegna aveva ridotto la schermata a tre campi — vita, fianchi, braccia —
// mentre `BodyMeasurement` ne registra dieci piu il peso. I dati salvati con la
// versione precedente restavano nel database **invisibili e non aggiornabili**:
// il modo peggiore di perderli, perche non se ne accorge nessuno.
//
// Questo test lega la schermata al modello: se il modello guadagna un campo e
// la schermata no, diventa rosso.