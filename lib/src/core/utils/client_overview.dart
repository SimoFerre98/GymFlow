import 'package:gymflow/src/models/consent.dart';
import 'package:gymflow/src/models/invite.dart';

/// Dopo quanti giorni senza allenarsi un cliente risulta «fermo da troppo
/// tempo»: **più di** questi giorni, quindi 7 è ancora in regola e 8 no.
/// Deciso con l'utente il 2026-10-19 (US-089).
const int kClientInactiveAfterDays = 7;

/// Cosa il trainer può dire dell'allenamento di un cliente.
///
/// Quattro stati e non due, perché «non lo so» e «non si è mai allenato» sono
/// cose diverse, e confonderle direbbe una cosa falsa: chi non ha concesso gli
/// allenamenti non ha un'attività da mostrare, e non la si inventa.
enum ClientActivity {
  /// Fermo da più di [kClientInactiveAfterDays] giorni: serve attenzione.
  overdue,

  /// Il cliente condivide gli allenamenti e non ne ha ancora fatto nessuno.
  noSessions,

  /// Si è allenato di recente.
  recent,

  /// Il cliente non ha concesso gli allenamenti: il trainer non può saperlo.
  notShared,
}

/// Una riga dell'elenco dei clienti.
class ClientRow {
  const ClientRow({
    required this.clientId,
    required this.name,
    required this.since,
    required this.invite,
    required this.activity,
    this.daysSinceLastSession,
  });

  final String clientId;
  final String name;

  /// Da quando il legame è attivo.
  final DateTime since;

  /// L'invito accettato che regge il legame.
  final Invite invite;
  final ClientActivity activity;

  /// Giorni dall'ultimo allenamento; solo per `recent` e `overdue`.
  final int? daysSinceLastSession;
}

/// Costruisce l'elenco dei clienti di [trainerId], già nell'ordine in cui si
/// legge.
///
/// - [relationships]: i legami accettati dell'utente, di **qualunque** tipo e
///   direzione (è ciò che dà `acceptedRelationshipsProvider`): qui si tengono
///   solo quelli `trainer_client` dove il trainer è lui. Per un legame
///   `trainer_client`, `fromUserId` è sempre il trainer.
/// - [consents]: i consensi ricevuti dal trainer.
/// - [lastSessions]: l'inizio dell'ultima sessione di ogni cliente **che è stato
///   letto**. Un cliente assente dalla mappa, o con valore nullo, non ha
///   un'ultima sessione nota.
///
/// **Ordine**: prima i fermi da più tempo, poi chi non ha ancora fatto
/// nessun allenamento, poi chi si è allenato di recente (dal più recente), in
/// fondo chi non condivide. A parità, per nome. Un trainer con dieci clienti
/// legge dall'alto le persone di cui occuparsi.
List<ClientRow> buildClientRows({
  required String trainerId,
  required List<Invite> relationships,
  required List<Consent> consents,
  required Map<String, DateTime?> lastSessions,
  required DateTime now,
}) {
  final perCliente = _clientiDelTrainer(trainerId, relationships);
  final concesso = _sessioniConcesse(trainerId, consents);

  final righe = <ClientRow>[
    for (final entry in perCliente.entries)
      _riga(
        invite: entry.value,
        sessioniCondivise: concesso[entry.key] ?? false,
        ultima: lastSessions[entry.key],
        now: now,
      ),
  ];

  righe.sort((a, b) {
    final gruppo = _gruppo(a.activity).compareTo(_gruppo(b.activity));
    if (gruppo != 0) return gruppo;
    // Dentro lo stesso gruppo: i fermi da più tempo per primi; i recenti dal
    // più recente. Gli altri due gruppi non hanno un numero.
    final ga = a.daysSinceLastSession ?? 0;
    final gb = b.daysSinceLastSession ?? 0;
    if (a.activity == ClientActivity.overdue && ga != gb) return gb.compareTo(ga);
    if (a.activity == ClientActivity.recent && ga != gb) return ga.compareTo(gb);
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return righe;
}

/// I legami `trainer_client` accettati dove il trainer è [trainerId], uno per
/// cliente.
///
/// Un solo legame per cliente: si può invitare due volte chi è già legato
/// (US-092, review), e la persona non deve comparire due volte. Vince il più
/// recente.
Map<String, Invite> _clientiDelTrainer(String trainerId, List<Invite> relationships) {
  final perCliente = <String, Invite>{};
  for (final invite in relationships) {
    if (invite.status != InviteStatus.accepted) continue;
    if (invite.relationshipType != RelationshipType.trainerClient) continue;
    if (invite.fromUserId != trainerId) continue;
    final attuale = perCliente[invite.toUserId];
    if (attuale == null || _dal(invite).isAfter(_dal(attuale))) {
      perCliente[invite.toUserId] = invite;
    }
  }
  return perCliente;
}

Map<String, bool> _sessioniConcesse(String trainerId, List<Consent> consents) => {
  for (final consent in consents)
    if (consent.trainerUserId == trainerId) consent.clientUserId: consent.grants.sessions,
};

DateTime _dal(Invite invite) => invite.respondedAt ?? invite.createdAt;

/// I clienti di cui **vale la pena** leggere l'ultima sessione: quelli con un
/// legame attivo che hanno concesso gli allenamenti. Gli altri non si leggono
/// affatto — le regole lo negherebbero, e una lettura negata e una lettura
/// sprecata.
List<String> clientsWithSharedSessions({
  required String trainerId,
  required List<Invite> relationships,
  required List<Consent> consents,
}) {
  final concesso = _sessioniConcesse(trainerId, consents);
  return [
    for (final id in _clientiDelTrainer(trainerId, relationships).keys)
      if (concesso[id] ?? false) id,
  ];
}

/// Le regole hanno negato la lettura: di norma il cliente ha revocato gli
/// allenamenti fra il caricamento dei consensi e la lettura.
class ClientReadDenied implements Exception {
  const ClientReadDenied();
  @override
  String toString() => 'ClientReadDenied';
}

/// Da dove [loadClientOverview] prende i dati. Un'interfaccia e non
/// `FirestoreService` perché la composizione — chi si legge, cosa succede se
/// una lettura è negata — deve potersi provare senza Firebase.
abstract interface class ClientOverviewSource {
  /// I legami accettati dell'utente, di qualunque tipo e direzione.
  Future<List<Invite>> acceptedRelationships();

  /// I consensi ricevuti dal trainer.
  Future<List<Consent>> consents();

  /// L'inizio dell'ultima sessione di [clientId], o `null` se non ne ha.
  /// Lancia [ClientReadDenied] se le regole negano la lettura.
  Future<DateTime?> lastSessionStart(String clientId);
}

/// Carica e compone l'elenco dei clienti.
///
/// **Una lettura per cliente che condivide gli allenamenti**, tutte insieme e
/// non una dopo l'altra, e **nessuna** per gli altri. Non c'è un tetto a dieci:
/// venticinque clienti sono venticinque letture, perché una query unica
/// perderebbe proprio il cliente fermo da più tempo (vedi `US-089.md`).
///
/// Se la lettura di un cliente è negata, quel cliente risulta «non condivide»
/// e l'elenco non cade: il consenso può essere stato revocato un istante fa.
/// Qualunque altro errore (la rete, per esempio) si propaga: mostrare «nessun
/// allenamento» a chi in realtà non si è riusciti a leggere sarebbe una bugia.
Future<List<ClientRow>> loadClientOverview({
  required String trainerId,
  required ClientOverviewSource source,
  required DateTime now,
}) async {
  final relationships = await source.acceptedRelationships();
  final consents = await source.consents();

  final daLeggere = clientsWithSharedSessions(
    trainerId: trainerId,
    relationships: relationships,
    consents: consents,
  );

  final ultime = <String, DateTime?>{};
  final negati = <String>{};
  await Future.wait([
    for (final id in daLeggere)
      () async {
        try {
          ultime[id] = await source.lastSessionStart(id);
        } on ClientReadDenied {
          negati.add(id);
        }
      }(),
  ]);

  return buildClientRows(
    trainerId: trainerId,
    relationships: relationships,
    // Un consenso revocato nel frattempo non vale più: il cliente passa a
    // «non condivide» invece di restare «nessun allenamento».
    consents: [for (final c in consents) if (!negati.contains(c.clientUserId)) c],
    lastSessions: ultime,
    now: now,
  );
}

int _gruppo(ClientActivity activity) => switch (activity) {
  ClientActivity.overdue => 0,
  ClientActivity.noSessions => 1,
  ClientActivity.recent => 2,
  ClientActivity.notShared => 3,
};

ClientRow _riga({
  required Invite invite,
  required bool sessioniCondivise,
  required DateTime? ultima,
  required DateTime now,
}) {
  final ClientActivity activity;
  int? giorni;
  if (!sessioniCondivise) {
    activity = ClientActivity.notShared;
  } else if (ultima == null) {
    activity = ClientActivity.noSessions;
  } else {
    giorni = _giorniFra(ultima, now);
    activity = giorni > kClientInactiveAfterDays ? ClientActivity.overdue : ClientActivity.recent;
  }
  return ClientRow(
    clientId: invite.toUserId,
    name: invite.toDisplayName,
    since: _dal(invite),
    invite: invite,
    activity: activity,
    daysSinceLastSession: giorni,
  );
}

/// Giorni **di calendario** da [da] a [a], mai negativi.
///
/// Si confrontano giorni e non istanti: un allenamento di ieri sera è «ieri»
/// anche alle otto del mattino, e il passaggio all'ora solare non sposta un
/// giorno. Una data nel futuro (un orologio sbagliato sul telefono del cliente)
/// vale 0, non un numero negativo che finirebbe in cima all'elenco.
int _giorniFra(DateTime da, DateTime a) {
  final giornoDa = DateTime.utc(da.year, da.month, da.day);
  final giornoA = DateTime.utc(a.year, a.month, a.day);
  final giorni = giornoA.difference(giornoDa).inDays;
  return giorni < 0 ? 0 : giorni;
}
