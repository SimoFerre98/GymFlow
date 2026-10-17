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
        {'sessions': true, 'measurements': false},
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

  group('consentSummaryKey: cosa legge il cliente', () {
    test('le quattro combinazioni hanno ciascuna la propria frase', () {
      expect(consentSummaryKey(ConsentGrants.none), 'consent_summary_none');
      expect(
        consentSummaryKey(const ConsentGrants(sessions: true)),
        'consent_summary_sessions',
      );
      expect(
        consentSummaryKey(const ConsentGrants(measurements: true)),
        'consent_summary_measurements',
      );
      expect(
        consentSummaryKey(const ConsentGrants(sessions: true, measurements: true)),
        'consent_summary_both',
      );
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
