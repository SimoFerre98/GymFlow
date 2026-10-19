import 'package:cloud_firestore/cloud_firestore.dart';

/// Le categorie che un cliente può concedere al proprio trainer.
///
/// **Due di lettura** (US-092), non quattro: una regola Firestore concede o nega
/// un documento intero, mai i suoi campi, e `sessions/{id}` contiene insieme
/// date, carichi, ripetizioni, RPE e note. Solo le misure corporee vivono in una
/// raccolta a sé.
///
/// **Una di scrittura** (US-113): [programs], a parte, perché leggere i dati e
/// scrivere le schede sono cose diverse e il cliente le decide separatamente.
///
/// [key] è il nome che le regole leggono in `grants`: cambiarlo qui senza
/// cambiare `firestore.rules` chiude l'accesso in silenzio.
enum ConsentCategory {
  /// Gli allenamenti completi: date, esercizi, carichi, ripetizioni, RPE, note.
  sessions,

  /// Peso e misure corporee nel tempo.
  measurements,

  /// Scrivere **nuove** schede per il cliente, e modificare solo quelle che ha
  /// scritto lui. Non è lettura: non apre le altre schede del cliente.
  programs;

  String get key => name;
}

/// Cosa il cliente ha concesso, categoria per categoria.
///
/// **Chiuso per predefinito**: una chiave mancante, o un valore che non è
/// esattamente `true`, vale `false`. Un dato malformato non deve mai
/// trasformarsi in una concessione.
class ConsentGrants {
  const ConsentGrants({this.sessions = false, this.measurements = false, this.programs = false});

  /// Niente concesso: lo stato di partenza, e quello dopo uno scioglimento.
  static const ConsentGrants none = ConsentGrants();

  final bool sessions;
  final bool measurements;

  /// Il trainer può scrivere nuove schede. Un consenso scritto prima di US-113 non
  /// ha la chiave e si legge come spento.
  final bool programs;

  bool isGranted(ConsentCategory category) => switch (category) {
    ConsentCategory.sessions => sessions,
    ConsentCategory.measurements => measurements,
    ConsentCategory.programs => programs,
  };

  /// Le categorie concesse, nell'ordine in cui si mostrano.
  List<ConsentCategory> get granted => [
    for (final category in ConsentCategory.values)
      if (isGranted(category)) category,
  ];

  bool get isNone => !sessions && !measurements && !programs;

  ConsentGrants withGrant(ConsentCategory category, bool value) => switch (category) {
    ConsentCategory.sessions =>
      ConsentGrants(sessions: value, measurements: measurements, programs: programs),
    ConsentCategory.measurements =>
      ConsentGrants(sessions: sessions, measurements: value, programs: programs),
    ConsentCategory.programs =>
      ConsentGrants(sessions: sessions, measurements: measurements, programs: value),
  };

  Map<String, bool> toMap() => {
    for (final category in ConsentCategory.values) category.key: isGranted(category),
  };

  factory ConsentGrants.fromMap(dynamic map) {
    if (map is! Map) return ConsentGrants.none;
    return ConsentGrants(
      sessions: map[ConsentCategory.sessions.key] == true,
      measurements: map[ConsentCategory.measurements.key] == true,
      programs: map[ConsentCategory.programs.key] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ConsentGrants &&
      other.sessions == sessions &&
      other.measurements == measurements &&
      other.programs == programs;

  @override
  int get hashCode => Object.hash(sessions, measurements, programs);
}

/// Le chiavi di localizzazione delle frasi che dicono, in parole, cosa può fare il
/// trainer: prima cosa **vede**, poi se può **scrivere** le schede. Funzione pura
/// e non uno `switch` dentro un widget: è ciò che il cliente legge per sapere
/// cosa ha concesso, e dev'essere verificabile.
///
/// Con tre permessi le combinazioni sono otto: non si elencano più a mano, si
/// compongono. Mai vuota: senza nulla di concesso dice che non vede niente.
List<String> consentSummaryKeys(ConsentGrants grants) {
  final frasi = <String>[
    if (grants.sessions && grants.measurements)
      'consent_summary_both'
    else if (grants.sessions)
      'consent_summary_sessions'
    else if (grants.measurements)
      'consent_summary_measurements',
    if (grants.programs) 'consent_summary_programs',
  ];
  return frasi.isEmpty ? const ['consent_summary_none'] : frasi;
}

/// Il consenso di un cliente verso un trainer (US-092).
///
/// Vive in `consents/{trainerUid}_{clientUid}`: l'id è **deterministico**
/// perché le regole non fanno ricerche, e per sapere se un trainer può leggere
/// i dati di un cliente costruiscono il percorso di un documento noto. Lo
/// scrive solo il cliente (vedi `firestore.rules`).
class Consent {
  const Consent({
    required this.id,
    required this.trainerUserId,
    required this.clientUserId,
    required this.inviteId,
    required this.grants,
    required this.updatedAt,
  });

  final String id;
  final String trainerUserId;
  final String clientUserId;

  /// L'invito accettato che regge questo consenso: se non è più `accepted`, le
  /// regole chiudono l'accesso anche se questo documento esiste ancora.
  final String inviteId;
  final ConsentGrants grants;
  final DateTime updatedAt;

  /// L'id del documento per una coppia trainer/cliente. Va tenuto uguale alla
  /// costruzione in `firestore.rules` (`percorsoConsenso`).
  static String idFor(String trainerUserId, String clientUserId) =>
      '${trainerUserId}_$clientUserId';

  Map<String, dynamic> toMap() => {
    'trainerUserId': trainerUserId,
    'clientUserId': clientUserId,
    'inviteId': inviteId,
    'grants': grants.toMap(),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory Consent.fromMap(Map<String, dynamic> map, String id) {
    return Consent(
      id: id,
      trainerUserId: map['trainerUserId'] ?? '',
      clientUserId: map['clientUserId'] ?? '',
      inviteId: map['inviteId'] ?? '',
      grants: ConsentGrants.fromMap(map['grants']),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
