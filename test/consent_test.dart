import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/models/consent.dart';

void main() {
  group('ConsentGrants', () {
    test('lo stato di partenza non concede niente', () {
      expect(ConsentGrants.none.sessions, isFalse);
      expect(ConsentGrants.none.measurements, isFalse);
      expect(ConsentGrants.none.isNone, isTrue);
      expect(ConsentGrants.none.granted, isEmpty);
    });

    test('ogni categoria si concede da sola, senza muovere l altra', () {
      final soloSessioni = ConsentGrants.none.withGrant(ConsentCategory.sessions, true);
      expect(soloSessioni.sessions, isTrue);
      expect(soloSessioni.measurements, isFalse);

      final soloMisure = ConsentGrants.none.withGrant(ConsentCategory.measurements, true);
      expect(soloMisure.sessions, isFalse);
      expect(soloMisure.measurements, isTrue);
    });

    test('si revoca una categoria lasciando intatta l altra', () {
      const entrambe = ConsentGrants(sessions: true, measurements: true);
      final senzaSessioni = entrambe.withGrant(ConsentCategory.sessions, false);
      expect(senzaSessioni.sessions, isFalse);
      expect(senzaSessioni.measurements, isTrue);
    });

    test('granted elenca le categorie concesse nell ordine in cui si mostrano', () {
      expect(
        const ConsentGrants(sessions: true, measurements: true).granted,
        [ConsentCategory.sessions, ConsentCategory.measurements],
      );
      expect(
        const ConsentGrants(measurements: true).granted,
        [ConsentCategory.measurements],
      );
    });

    test('toMap usa le chiavi che le regole leggono', () {
      // Se queste chiavi cambiano senza cambiare `firestore.rules`, l'accesso
      // si chiude in silenzio: e il test dell'emulatore non se ne accorge,
      // perche' scrive le proprie.
      expect(
        const ConsentGrants(sessions: true).toMap(),
        {'sessions': true, 'measurements': false, 'programs': false},
      );
    });

    group('lettura: chiuso per predefinito', () {
      test('un documento senza grants non concede niente', () {
        expect(ConsentGrants.fromMap(null), ConsentGrants.none);
      });

      test('un grants che non e una mappa non concede niente', () {
        expect(ConsentGrants.fromMap('true'), ConsentGrants.none);
        expect(ConsentGrants.fromMap(true), ConsentGrants.none);
        expect(ConsentGrants.fromMap(const <bool>[true, true]), ConsentGrants.none);
      });

      test('una chiave mancante vale falso', () {
        expect(
          ConsentGrants.fromMap({'sessions': true}),
          const ConsentGrants(sessions: true),
        );
      });

      test('un valore che non e esattamente true vale falso', () {
        // Una stringa "true" o un 1 sono dati malformati: non devono
        // trasformarsi in una concessione.
        expect(
          ConsentGrants.fromMap({'sessions': 'true', 'measurements': 1}),
          ConsentGrants.none,
        );
      });
    });
  });

  group('consentSummaryKeys: cosa legge il cliente', () {
    test('senza niente concesso dice che non vede nulla, mai una lista vuota', () {
      expect(consentSummaryKeys(ConsentGrants.none), ['consent_summary_none']);
    });

    test('le otto combinazioni, ciascuna con le sue frasi', () {
      const casi = <(ConsentGrants, List<String>)>[
        (ConsentGrants.none, ['consent_summary_none']),
        (ConsentGrants(sessions: true), ['consent_summary_sessions']),
        (ConsentGrants(measurements: true), ['consent_summary_measurements']),
        (ConsentGrants(sessions: true, measurements: true), ['consent_summary_both']),
        (ConsentGrants(programs: true), ['consent_summary_programs']),
        (ConsentGrants(sessions: true, programs: true), ['consent_summary_sessions', 'consent_summary_programs']),
        (ConsentGrants(measurements: true, programs: true), ['consent_summary_measurements', 'consent_summary_programs']),
        (ConsentGrants(sessions: true, measurements: true, programs: true), ['consent_summary_both', 'consent_summary_programs']),
      ];
      for (final (grants, attese) in casi) {
        expect(consentSummaryKeys(grants), attese, reason: '$grants');
      }
    });

    test('scrivere le schede non conta come vedere i dati: «non vede nulla» sparisce solo se c è qualcosa da dire', () {
      // Con solo `programs` la frase è quella del permesso di scrittura, non
      // «Vede: …»: il trainer non legge niente.
      expect(consentSummaryKeys(const ConsentGrants(programs: true)), isNot(contains('consent_summary_both')));
      expect(consentSummaryKeys(const ConsentGrants(programs: true)), isNot(contains('consent_summary_none')));
    });
  });

  group('il permesso di scrittura (US-113)', () {
    test('è spento di default e non muove le altre categorie', () {
      expect(ConsentGrants.none.programs, isFalse);
      final solo = ConsentGrants.none.withGrant(ConsentCategory.programs, true);
      expect(solo.programs, isTrue);
      expect(solo.sessions, isFalse);
      expect(solo.measurements, isFalse);
    });

    test('accendere o spegnere le altre categorie non tocca il permesso di scrittura', () {
      const tutto = ConsentGrants(sessions: true, measurements: true, programs: true);
      final senzaSessioni = tutto.withGrant(ConsentCategory.sessions, false);
      expect(senzaSessioni.programs, isTrue);
      expect(tutto.withGrant(ConsentCategory.programs, false).sessions, isTrue);
    });

    test('toMap ha le tre chiavi che le regole leggono', () {
      expect(
        const ConsentGrants(programs: true).toMap(),
        {'sessions': false, 'measurements': false, 'programs': true},
      );
    });

    test('un consenso scritto prima di US-113, senza la chiave, si legge con la scrittura spenta', () {
      final vecchio = ConsentGrants.fromMap({'sessions': true, 'measurements': true});
      expect(vecchio.programs, isFalse);
      expect(vecchio.sessions, isTrue);
    });

    test('un valore che non è esattamente true non concede la scrittura', () {
      expect(ConsentGrants.fromMap({'programs': 'true'}).programs, isFalse);
      expect(ConsentGrants.fromMap({'programs': 1}).programs, isFalse);
      expect(ConsentGrants.fromMap({'programs': null}).programs, isFalse);
    });

    test('granted elenca le tre categorie nell ordine in cui si mostrano', () {
      expect(
        const ConsentGrants(sessions: true, measurements: true, programs: true).granted,
        [ConsentCategory.sessions, ConsentCategory.measurements, ConsentCategory.programs],
      );
    });

    test('l uguaglianza distingue il permesso di scrittura', () {
      expect(const ConsentGrants(programs: true), isNot(const ConsentGrants()));
      expect(const ConsentGrants(programs: true), const ConsentGrants(programs: true));
    });
  });

  group('Consent', () {
    test('l id e trainer_cliente, come lo ricostruiscono le regole', () {
      expect(Consent.idFor('trainer-1', 'cliente-9'), 'trainer-1_cliente-9');
    });

    test('round-trip: tutti i campi sopravvivono', () {
      final original = Consent(
        id: 't_c',
        trainerUserId: 't',
        clientUserId: 'c',
        inviteId: 'inv-1',
        grants: const ConsentGrants(sessions: true),
        updatedAt: DateTime.utc(2026, 10, 17, 9, 30),
      );
      final restored = Consent.fromMap(original.toMap(), original.id);

      expect(restored.id, original.id);
      expect(restored.trainerUserId, original.trainerUserId);
      expect(restored.clientUserId, original.clientUserId);
      expect(restored.inviteId, original.inviteId);
      expect(restored.grants, original.grants);
      expect(restored.updatedAt.toUtc(), original.updatedAt.toUtc());
    });

    test('toMap non contiene altro che i campi che le regole ammettono', () {
      final map = Consent(
        id: 't_c',
        trainerUserId: 't',
        clientUserId: 'c',
        inviteId: 'inv-1',
        grants: ConsentGrants.none,
        updatedAt: DateTime.utc(2026, 10, 17),
      ).toMap();
      // `hasOnly([...])` in `firestore.rules`: un campo in piu' farebbe negare
      // la creazione con un permesso negato difficile da capire.
      expect(
        map.keys.toSet(),
        {'trainerUserId', 'clientUserId', 'inviteId', 'grants', 'updatedAt'},
      );
      expect(map['updatedAt'], isA<Timestamp>());
    });

    test('un documento vuoto si legge chiuso, senza lanciare', () {
      final restored = Consent.fromMap(const {}, 't_c');
      expect(restored.grants, ConsentGrants.none);
      expect(restored.trainerUserId, '');
    });
  });
}
