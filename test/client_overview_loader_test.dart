import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/src/core/utils/client_overview.dart';
import 'package:gymflow/src/models/consent.dart';
import 'package:gymflow/src/models/invite.dart';

/// Il caricamento dell'elenco clienti (US-089): quante letture fa, quali, e
/// cosa succede quando una è negata o fallisce.
///
/// Prova il criterio riscritto il 2026-10-19: una lettura per cliente che
/// condivide gli allenamenti, in parallelo, nessuna per gli altri, nessun tetto.
class FintaSorgente implements ClientOverviewSource {
  FintaSorgente({
    required this.legami,
    required this.consensi,
    this.ultime = const {},
    this.negati = const {},
    this.fallisce = const {},
  });

  final List<Invite> legami;
  final List<Consent> consensi;
  final Map<String, DateTime?> ultime;
  final Set<String> negati;
  final Set<String> fallisce;

  final List<String> lette = [];
  int inVolo = 0;
  int massimoInVolo = 0;

  /// Se impostato, ogni lettura aspetta questo prima di rispondere: serve a
  /// vedere se partono tutte insieme o una per volta.
  Completer<void>? cancello;

  @override
  Future<List<Invite>> acceptedRelationships() async => legami;

  @override
  Future<List<Consent>> consents() async => consensi;

  @override
  Future<DateTime?> lastSessionStart(String clientId) async {
    lette.add(clientId);
    inVolo++;
    if (inVolo > massimoInVolo) massimoInVolo = inVolo;
    try {
      if (cancello != null) await cancello!.future;
      if (negati.contains(clientId)) throw const ClientReadDenied();
      if (fallisce.contains(clientId)) throw StateError('rete assente');
      return ultime[clientId];
    } finally {
      inVolo--;
    }
  }
}

void main() {
  const io = 'trainer-1';
  final oggi = DateTime(2026, 10, 19, 10);

  Invite legame(String cliente, {RelationshipType tipo = RelationshipType.trainerClient, String trainer = io}) =>
      Invite(
        id: 'inv-$cliente',
        fromUserId: trainer,
        fromDisplayName: 'Tina',
        fromRole: 'trainer',
        toUserId: cliente,
        toDisplayName: 'Cliente $cliente',
        code: 'CODE',
        relationshipType: tipo,
        status: InviteStatus.accepted,
        createdAt: DateTime(2026, 9, 1),
        expiresAt: DateTime(2026, 9, 8),
        respondedAt: DateTime(2026, 9, 2),
      );

  Consent consenso(String cliente, {bool sessioni = true, String trainer = io}) => Consent(
    id: '${trainer}_$cliente',
    trainerUserId: trainer,
    clientUserId: cliente,
    inviteId: 'inv-$cliente',
    grants: ConsentGrants(sessions: sessioni),
    updatedAt: DateTime(2026, 9, 2),
  );

  Future<List<ClientRow>> carica(FintaSorgente fonte) =>
      loadClientOverview(trainerId: io, source: fonte, now: oggi);

  group('quali clienti si leggono', () {
    test('una lettura per cliente che condivide gli allenamenti, nessuna per gli altri', () async {
      final fonte = FintaSorgente(
        legami: [legame('a'), legame('b'), legame('c'), legame('d')],
        consensi: [
          consenso('a'),
          consenso('b', sessioni: false), // consenso ma sessioni spente
          // 'c' non ha nessun consenso
          consenso('d'),
        ],
        ultime: {'a': DateTime(2026, 10, 18), 'd': DateTime(2026, 10, 1)},
      );
      final righe = await carica(fonte);

      expect(fonte.lette.toSet(), {'a', 'd'}, reason: 'solo chi condivide');
      expect(fonte.lette, hasLength(2), reason: 'una lettura ciascuno, non di più');
      expect(righe, hasLength(4), reason: 'gli altri compaiono comunque, come «non condivide»');
    });

    test('non si legge chi ha un consenso ma nessun legame attivo con il trainer', () async {
      final fonte = FintaSorgente(
        legami: [legame('amico', tipo: RelationshipType.friend)],
        consensi: [consenso('amico'), consenso('altro', trainer: 'altro-trainer')],
      );
      await carica(fonte);
      expect(fonte.lette, isEmpty);
    });

    test('senza clienti non legge niente e restituisce un elenco vuoto', () async {
      final fonte = FintaSorgente(legami: const [], consensi: const []);
      expect(await carica(fonte), isEmpty);
      expect(fonte.lette, isEmpty);
    });
  });

  group('nessun tetto a dieci', () {
    test('venticinque clienti che condividono: venticinque letture e venticinque righe', () async {
      final ids = [for (var i = 0; i < 25; i++) 'c$i'];
      final fonte = FintaSorgente(
        legami: [for (final id in ids) legame(id)],
        consensi: [for (final id in ids) consenso(id)],
        ultime: {for (final id in ids) id: DateTime(2026, 10, 18)},
      );
      final righe = await carica(fonte);

      expect(fonte.lette, hasLength(25));
      expect(fonte.lette.toSet(), ids.toSet(), reason: 'nessuno saltato');
      expect(righe, hasLength(25));
      expect(righe.every((r) => r.activity == ClientActivity.recent), isTrue);
    });
  });

  group('in parallelo', () {
    test('le letture partono tutte insieme, non una dopo l altra', () async {
      final ids = [for (var i = 0; i < 12; i++) 'c$i'];
      final fonte = FintaSorgente(
        legami: [for (final id in ids) legame(id)],
        consensi: [for (final id in ids) consenso(id)],
      )..cancello = Completer<void>();

      final futuro = carica(fonte);
      // Si lascia girare il ciclo degli eventi: se fossero sequenziali, ne
      // sarebbe partita una sola e le altre aspetterebbero la sua risposta.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(fonte.massimoInVolo, 12);

      fonte.cancello!.complete();
      expect(await futuro, hasLength(12));
    });
  });

  group('quando una lettura non va', () {
    test('una lettura negata fa passare quel cliente a «non condivide», senza far cadere l elenco', () async {
      final fonte = FintaSorgente(
        legami: [legame('a'), legame('b')],
        consensi: [consenso('a'), consenso('b')],
        ultime: {'a': DateTime(2026, 10, 18), 'b': DateTime(2026, 10, 18)},
        negati: {'b'}, // il cliente ha revocato un istante fa
      );
      final righe = await carica(fonte);
      final perId = {for (final r in righe) r.clientId: r.activity};

      expect(perId['a'], ClientActivity.recent);
      expect(perId['b'], ClientActivity.notShared, reason: 'non «nessun allenamento»: sarebbe falso');
    });

    test('un errore diverso, come la rete, si propaga invece di diventare «nessun allenamento»', () async {
      final fonte = FintaSorgente(
        legami: [legame('a'), legame('b')],
        consensi: [consenso('a'), consenso('b')],
        fallisce: {'b'},
      );
      await expectLater(carica(fonte), throwsA(isA<StateError>()));
    });

    test('un cliente senza sessioni è «nessun allenamento», non «non condivide»', () async {
      final fonte = FintaSorgente(
        legami: [legame('a')],
        consensi: [consenso('a')],
        ultime: {'a': null},
      );
      expect((await carica(fonte)).single.activity, ClientActivity.noSessions);
    });
  });
}
