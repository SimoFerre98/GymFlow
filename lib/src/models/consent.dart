import 'package:cloud_firestore/cloud_firestore.dart';

/// Le due categorie che un cliente può concedere al proprio trainer (US-092).
///
/// Sono due e non quattro perché una regola Firestore concede o nega un
/// documento intero, mai i suoi campi: `sessions/{id}` contiene insieme date,
/// carichi, ripetizioni, RPE e note, e non c'è modo di mostrarne una parte.
/// Solo le misure corporee vivono in una raccolta a sé.
///
/// [key] è il nome che le regole leggono in `grants`: cambiarlo qui senza
/// cambiare `firestore.rules` chiude l'accesso in silenzio.
enum ConsentCategory {
  /// Gli allenamenti completi: date, esercizi, carichi, ripetizioni, RPE, note.
  sessions,

  /// Peso e misure corporee nel tempo.
  measurements;

  String get key => name;
}

/// Cosa il cliente ha concesso, categoria per categoria.
///
/// **Chiuso per predefinito**: una chiave mancante, o un valore che non è
/// esattamente `true`, vale `false`. Un dato malformato non deve mai
/// trasformarsi in una concessione.
class ConsentGrants {
  const ConsentGrants({this.sessions = false, this.measurements = false});

  /// Niente concesso: lo stato di partenza, e quello dopo uno scioglimento.
  static const ConsentGrants none = ConsentGrants();

  final bool sessions;
  final bool measurements;

  bool isGranted(ConsentCategory category) => switch (category) {
    ConsentCategory.sessions => sessions,
    ConsentCategory.measurements => measurements,
  };

  /// Le categorie concesse, nell'ordine in cui si mostrano.
  List<ConsentCategory> get granted => [
    for (final category in ConsentCategory.values)
      if (isGranted(category)) category,
  ];

  bool get isNone => !sessions && !measurements;

  ConsentGrants withGrant(ConsentCategory category, bool value) => switch (category) {
    ConsentCategory.sessions => ConsentGrants(sessions: value, measurements: measurements),
    ConsentCategory.measurements => ConsentGrants(sessions: sessions, measurements: value),
  };

  Map<String, bool> toMap() => {
    for (final category in ConsentCategory.values) category.key: isGranted(category),
  };

  factory ConsentGrants.fromMap(dynamic map) {
    if (map is! Map) return ConsentGrants.none;
    return ConsentGrants(
      sessions: map[ConsentCategory.sessions.key] == true,
      measurements: map[ConsentCategory.measurements.key] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ConsentGrants && other.sessions == sessions && other.measurements == measurements;

  @override
  int get hashCode => Object.hash(sessions, measurements);
}

/// La chiave di localizzazione della frase che dice, in parole, cosa vede il
/// trainer. Funzione pura e non un `switch` dentro un widget: è ciò che il
/// cliente legge per sapere cosa ha concesso, e dev'essere verificabile.
String consentSummaryKey(ConsentGrants grants) {
  if (grants.sessions && grants.measurements) return 'consent_summary_both';
  if (grants.sessions) return 'consent_summary_sessions';
  if (grants.measurements) return 'consent_summary_measurements';
  return 'consent_summary_none';
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
