import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/utils/client_overview.dart';
import 'package:gymflow/src/models/consent.dart';
import 'package:gymflow/src/models/invite.dart';

/// Le righe dell'elenco clienti del trainer (US-089): chi compare, cosa si può
/// dire di ciascuno, in che ordine.
void main() {
  const io = 'trainer-1';
  final oggi = DateTime(2026, 10, 19, 10, 0);

  Invite legame({
    String id = 'inv-1',
    String trainer = io,
    String cliente = 'c1',
    String nome = 'Carlo',
    RelationshipType tipo = RelationshipType.trainerClient,
    InviteStatus stato = InviteStatus.accepted,
    DateTime? dal,
  }) => Invite(
    id: id,
    fromUserId: trainer,
    fromDisplayName: 'Tina',
    fromRole: 'trainer',
    toUserId: cliente,
    toDisplayName: nome,
    code: 'CODE',
    relationshipType: tipo,
    status: stato,
    createdAt: DateTime(2026, 9, 1),
    expiresAt: DateTime(2026, 9, 8),
    respondedAt: dal ?? DateTime(2026, 9, 2),
  );

  Consent consenso(String cliente, {bool sessioni = true, bool misure = false}) => Consent(
    id: '${io}_$cliente',
    trainerUserId: io,
    clientUserId: cliente,
    inviteId: 'inv-1',
    grants: ConsentGrants(sessions: sessioni, measurements: misure),
    updatedAt: DateTime(2026, 9, 2),
  );

  List<ClientRow> righe({
    required List<Invite> legami,
    List<Consent> consensi = const [],
    Map<String, DateTime?> ultime = const {},
  }) => buildClientRows(
    trainerId: io,
    relationships: legami,
    consents: consensi,
    lastSessions: ultime,
    now: oggi,
  );

  group('chi compare', () {
    test('un cliente con un legame trainer_client accettato', () {
      final r = righe(legami: [legame()]);
      expect(r, hasLength(1));
      expect(r.single.name, 'Carlo');
      expect(r.single.clientId, 'c1');
    });

    test('non compaiono gli amici', () {
      expect(righe(legami: [legame(tipo: RelationshipType.friend)]), isEmpty);
    });

    test('non compaiono i legami in cui il trainer è l altro', () {
      // Io sono il cliente di qualcun altro: quel legame non fa di me il suo trainer.
      expect(righe(legami: [legame(trainer: 'altro-trainer', cliente: io)]), isEmpty);
    });

    test('non compaiono inviti in sospeso, rifiutati o sciolti', () {
      for (final stato in [InviteStatus.pending, InviteStatus.declined, InviteStatus.revoked]) {
        expect(righe(legami: [legame(stato: stato)]), isEmpty, reason: '$stato');
      }
    });

    test('un cliente invitato due volte compare una volta, con il legame più recente', () {
      final r = righe(
        legami: [
          legame(id: 'vecchio', dal: DateTime(2026, 9, 2)),
          legame(id: 'nuovo', dal: DateTime(2026, 10, 1)),
        ],
      );
      expect(r, hasLength(1));
      expect(r.single.invite.id, 'nuovo');
    });

    test('vince il più recente anche quando nella lista viene prima', () {
      // Senza questo, «vince l'ultimo della lista» passerebbe per coincidenza:
      // nel test sopra il più recente è anche l'ultimo.
      final r = righe(
        legami: [
          legame(id: 'nuovo', dal: DateTime(2026, 10, 1)),
          legame(id: 'vecchio', dal: DateTime(2026, 9, 2)),
        ],
      );
      expect(r, hasLength(1));
      expect(r.single.invite.id, 'nuovo');
    });

    test('nessun legame, nessuna riga', () {
      expect(righe(legami: const []), isEmpty);
    });

    test('venticinque clienti sono venticinque righe: non si tronca a dieci', () {
      final legami = [for (var i = 0; i < 25; i++) legame(id: 'i$i', cliente: 'c$i', nome: 'Cliente $i')];
      expect(righe(legami: legami), hasLength(25));
    });
  });

  group('cosa si può dire dell allenamento', () {
    test('senza consenso: non condivisi, e nessun numero', () {
      final r = righe(legami: [legame()]).single;
      expect(r.activity, ClientActivity.notShared);
      expect(r.daysSinceLastSession, isNull);
    });

    test('con il consenso ma sessioni spente: non condivisi', () {
      final r = righe(
        legami: [legame()],
        consensi: [consenso('c1', sessioni: false, misure: true)],
        // Anche se per sbaglio qualcuno avesse letto una data: non si mostra.
        ultime: {'c1': DateTime(2026, 10, 18)},
      ).single;
      expect(r.activity, ClientActivity.notShared);
      expect(r.daysSinceLastSession, isNull);
    });

    test('un consenso di un altro trainer non conta', () {
      final altro = Consent(
        id: 'altro_c1',
        trainerUserId: 'altro',
        clientUserId: 'c1',
        inviteId: 'x',
        grants: const ConsentGrants(sessions: true),
        updatedAt: DateTime(2026, 9, 2),
      );
      final r = righe(legami: [legame()], consensi: [altro]).single;
      expect(r.activity, ClientActivity.notShared);
    });

    test('condivisi e nessuna sessione: lo dice, non lo confonde con «non condivide»', () {
      final r = righe(legami: [legame()], consensi: [consenso('c1')]).single;
      expect(r.activity, ClientActivity.noSessions);
      expect(r.daysSinceLastSession, isNull);
    });

    test('condivisi e con una sessione: i giorni dall ultima', () {
      final r = righe(
        legami: [legame()],
        consensi: [consenso('c1')],
        ultime: {'c1': DateTime(2026, 10, 16, 18, 30)},
      ).single;
      expect(r.activity, ClientActivity.recent);
      expect(r.daysSinceLastSession, 3);
    });
  });

  group('i giorni, e la soglia', () {
    ClientRow conUltima(DateTime ultima) => righe(
      legami: [legame()],
      consensi: [consenso('c1')],
      ultime: {'c1': ultima},
    ).single;

    test('oggi vale 0, anche a mezzanotte e un minuto', () {
      expect(conUltima(DateTime(2026, 10, 19, 0, 1)).daysSinceLastSession, 0);
    });

    test('ieri sera è 1 anche alle dieci del mattino', () {
      expect(conUltima(DateTime(2026, 10, 18, 23, 0)).daysSinceLastSession, 1);
    });

    test('sette giorni è ancora in regola', () {
      final r = conUltima(DateTime(2026, 10, 12));
      expect(r.daysSinceLastSession, 7);
      expect(r.activity, ClientActivity.recent);
    });

    test('otto giorni è fermo da troppo tempo', () {
      final r = conUltima(DateTime(2026, 10, 11));
      expect(r.daysSinceLastSession, 8);
      expect(r.activity, ClientActivity.overdue);
    });

    test('il passaggio all ora solare non sposta il conto', () {
      // Il 25 ottobre 2026 si torna all'ora solare: un giorno di 25 ore.
      final r = buildClientRows(
        trainerId: io,
        relationships: [legame()],
        consents: [consenso('c1')],
        lastSessions: {'c1': DateTime(2026, 10, 24, 23, 30)},
        now: DateTime(2026, 10, 26, 8, 0),
      ).single;
      expect(r.daysSinceLastSession, 2);
    });

    test('una data nel futuro vale 0, non un numero negativo', () {
      final r = conUltima(DateTime(2026, 10, 25));
      expect(r.daysSinceLastSession, 0);
      expect(r.activity, ClientActivity.recent);
    });

    test('la soglia è quella dichiarata', () {
      expect(kClientInactiveAfterDays, 7);
    });
  });

  group('l ordine', () {
    test('fermi da più tempo, poi senza allenamenti, poi recenti, in fondo chi non condivide', () {
      final legami = [
        legame(id: 'a', cliente: 'a', nome: 'Anna'), // non condivide
        legame(id: 'b', cliente: 'b', nome: 'Bruno'), // ieri
        legame(id: 'c', cliente: 'c', nome: 'Carla'), // 20 giorni
        legame(id: 'd', cliente: 'd', nome: 'Dario'), // nessuna sessione
        legame(id: 'e', cliente: 'e', nome: 'Elena'), // 9 giorni
        legame(id: 'f', cliente: 'f', nome: 'Franco'), // 3 giorni
      ];
      final r = righe(
        legami: legami,
        consensi: [for (final id in ['b', 'c', 'd', 'e', 'f']) consenso(id)],
        ultime: {
          'b': DateTime(2026, 10, 18),
          'c': DateTime(2026, 9, 29),
          'd': null,
          'e': DateTime(2026, 10, 10),
          'f': DateTime(2026, 10, 16),
        },
      );
      expect(r.map((x) => x.name).toList(), [
        'Carla', // 20 giorni
        'Elena', // 9 giorni
        'Dario', // nessun allenamento
        'Bruno', // 1 giorno
        'Franco', // 3 giorni
        'Anna', // non condivide
      ]);
    });

    test('a parità, per nome senza badare alle maiuscole', () {
      final r = righe(
        legami: [
          legame(id: '1', cliente: '1', nome: 'zoe'),
          legame(id: '2', cliente: '2', nome: 'Aldo'),
          legame(id: '3', cliente: '3', nome: 'marco'),
        ],
      );
      expect(r.map((x) => x.name).toList(), ['Aldo', 'marco', 'zoe']);
    });
  });
}
