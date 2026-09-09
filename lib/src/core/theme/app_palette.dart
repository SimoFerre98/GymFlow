import 'package:flutter/material.dart';
/// Colori di GymFlow — direzione "Immersivo / Toxic Forest".
///
/// Scelti dal prodotto con riferimenti visivi (`docs/design/05-immersivo-toxic-forest.html`),
/// non derivati algoritmicamente: i rapporti di contrasto di ogni coppia usata
/// dall'interfaccia sono misurati e verificati da `test/contrast_test.dart`.
///
/// Qui ci sono soltanto i valori. La loro assegnazione ai ruoli Material 3
/// avviene in `app_theme.dart`: chi cerca "di che colore e un bottone" guarda
/// il tema, non questo file.
abstract final class AppPalette {
  // ── Toxic Forest: la famiglia che porta le superfici ────────────────────
  /// Sfondo dell'applicazione. Il piu scuro: tutto il resto emerge da qui.
  static const Color bgDeep = Color(0xFF0B2027);
  /// Superficie delle card.
  static const Color surfaceCard = Color(0xFF143540);
  /// Superficie sollevata: card dentro card, elementi flottanti.
  static const Color surfaceRaised = Color(0xFF1E4B5A);
  /// Bordi e separatori sulle superfici scure. Sostituisce l'ombra: qui i
  /// confini si disegnano con una linea, non con elevazione.
  static const Color outline = Color(0xFF286274);
  /// Elementi di supporto che non sono azioni.
  static const Color support = Color(0xFF5F9C93);
  // ── Accenti: uno per le azioni, uno per i dati ─────────────────────────
  /// Giallo neon. **Un solo significato: cosa fare adesso.**
  ///
  /// Se compare su qualcosa che non e un'azione, l'occhio impara a ignorarlo
  /// e il colore perde la sua funzione.
  static const Color accent = Color(0xFFEEF800);
  /// Giallo neon spento, per gli stati disabilitati e i contenitori.
  static const Color accentMuted = Color(0xFF6E7300);
  /// Verde bosco. Riservato ai **dati vitali**: battito, sforzo percepito.
  ///
  /// Distinto dal giallo di proposito: una metrica non e un pulsante.
  static const Color accentSecondary = Color(0xFF80B918);
  /// Verde bosco spento, per i contenitori.
  static const Color accentSecondaryMuted = Color(0xFF4B6B0E);
  // ── Neutri ──────────────────────────────────────────────────────────────
  /// Bianco freddo, virato verso il teal: un bianco puro sul fondo scuro
  /// sembrerebbe staccato.
  static const Color paper = Color(0xFFEAF6F2);
  /// Testo secondario sulle superfici scure.
  static const Color paperDim = Color(0xFF8FB3AC);
  // ── Tema chiaro ─────────────────────────────────────────────────────────
  /// Fondo del tema chiaro, con la stessa vira verso il teal.
  static const Color lightBackground = Color(0xFFF0F7F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFE0ECEF);
  /// Testo sul tema chiaro.
  static const Color lightOnSurface = Color(0xFF0B2027);
  static const Color lightOnSurfaceDim = Color(0xFF4B6B70);
  /// Sul tema chiaro il giallo neon non ha contrasto sufficiente per il
  /// testo: serve una variante scurita per i ruoli testuali.
  static const Color accentOnLight = Color(0xFF5C6300);
  /// Idem per il verde bosco.
  static const Color accentSecondaryOnLight = Color(0xFF3F5C0C);
  // ── Semantici: separati dagli accenti ──────────────────────────────────
  static const Color success = Color(0xFF7BC49A);
  static const Color warning = Color(0xFFE8B54A);
  static const Color danger = Color(0xFFE2685C);
  // ── Categorico: identita di serie in un grafico, non un'azione ──────────
  /// Le tinte per distinguere categorie in un grafico — per esempio i tipi
  /// di allenamento in un grafico a torta — dove servono piu tinte
  /// genuinamente separate di quante ne offra il `ColorScheme` (teal, giallo
  /// neon, verde bosco). Giallo e verde restano riservati al loro significato
  /// e non entrano in questo elenco.
  ///
  /// Valori e **ordine** dalla palette di riferimento del skill "dataviz"
  /// (i primi quattro slot, gia validati per accoppiamenti in entrambe le
  /// direzioni di daltonismo), verificati con
  /// `validate_palette.js "#3987E5,#D95926,#199E70,#C98500" --mode dark
  /// --surface "#0B2027"` sulla superficie di [bgDeep]: tutti i controlli
  /// passano. L'ordine e fisso e non si ricicla: una quinta categoria non
  /// genera una quinta tinta, ricade su un neutro.
  static const Color categoryBlue = Color(0xFF3987E5);
  static const Color categoryOrange = Color(0xFFD95926);
  static const Color categoryAqua = Color(0xFF199E70);
  static const Color categoryYellow = Color(0xFFC98500);
  /// Preset che l'utente puo scegliere per etichettare una scheda: e un tag
  /// personale, non un ruolo del tema, e per questo resta fuori dal
  /// `ColorScheme` — cosi come [accentPresets] qui sotto per il colore delle
  /// azioni. Interi e non `Color`: e cosi che il modello lo salva su Firestore.
  static const List<int> programColorPresets = <int>[
    0xFFF44336, // Rosso
    0xFFE91E63, // Rosa
    0xFF9C27B0, // Viola
    0xFF2196F3, // Blu
    0xFF00BCD4, // Ciano
    0xFF4CAF50, // Verde
    0xFFFFEB3B, // Giallo
    0xFFFF9800, // Arancio
    0xFF795548, // Marrone
    0xFF607D8B, // Blu grigio
  ];
  /// Colore di una scheda appena creata, prima che l'utente ne scelga uno.
  static const int defaultProgramColor = 0xFF2196F3;
  /// Preset che l'utente puo scegliere come colore delle azioni.
  ///
  /// Ognuno supera 4,5:1 su [bgDeep] e su [surfaceCard]: la scelta e libera
  /// dentro un insieme che non produce testo illeggibile.
  /// Verificato da `test/contrast_test.dart`.
  static const List<Color> accentPresets = <Color>[
    accent, // giallo neon, predefinito
    accentSecondary, // verde bosco
    Color(0xFF00F5D4), // teal fluor
    Color(0xFF57CC99), // salvia brillante
    Color(0xFF80FFDB), // acquamarina
    Color(0xFFAACC00), // lime
  ];
}
/// Le 4 palette complete fra cui l'utente scieglie in Aspetto — non solo
/// l'accento, l'intera atmosfera (mockup 3d, sezione "PALETTE").
///
/// [toxicForest] e la direzione predefinita dell'app (ADR-002): delega ai
/// valori di [AppPalette] invece di ripeterli, cosi i due non possono
/// disallinearsi. Le altre 3 portano valori propri, presi dagli esadecimali
/// esatti del mockup dove il mockup li mostra (sfondo, superficie, dato
/// vitale, accento — le 4 tinte della striscia-anteprima di ogni riquadro);
/// il resto (superficie sollevata, bordo, tema chiaro, preset) e stato scelto
/// per restare nella stessa famiglia cromatica e verificato con
/// `test/contrast_test.dart`.
///
/// **Due scostamenti dichiarati dal mockup**, entrambi per accessibilita:
/// - [digitalPulse.defaultTertiary]: il mockup mostra `#A855F7`, ma quel
///   viola non supera 4,5:1 su nessuna delle superfici scure di questa
///   palette (3,85:1 sulla card, 3,24:1 su quella sollevata). Uso `#C084FC`,
///   la stessa famiglia piu chiara, che supera 4,5:1 ovunque.
/// - [deepSeaNeon.darkSurface]: il mockup mostra `#003566` nello slot che
///   nell'enum precedente (`ab08290`) era `darkSurfaceHigh`; il suo vecchio
///   `darkSurface` (`#001D3D`) non compare piu nel mockup. Adottato il valore
///   del mockup e ricavata una nuova superficie sollevata (`#004B80`) a meta
///   strada verso il bordo esistente.
enum AppThemeStyle {
  classico,
  digitalPulse,
  toxicForest,
  deepSeaNeon;
  /// Chiave di localizzazione del nome mostrato nel selettore.
  String get labelKey => switch (this) {
    AppThemeStyle.classico => 'theme_style_classico',
    AppThemeStyle.digitalPulse => 'theme_style_digital_pulse',
    AppThemeStyle.toxicForest => 'theme_style_toxic_forest',
    AppThemeStyle.deepSeaNeon => 'theme_style_deep_sea_neon',
  };
  Color get darkBackground => switch (this) {
    AppThemeStyle.classico => const Color(0xFF221E3A),
    AppThemeStyle.digitalPulse => const Color(0xFF0F172A),
    AppThemeStyle.toxicForest => AppPalette.bgDeep,
    AppThemeStyle.deepSeaNeon => const Color(0xFF000814),
  };
  Color get darkSurface => switch (this) {
    AppThemeStyle.classico => const Color(0xFF48426D),
    AppThemeStyle.digitalPulse => const Color(0xFF2E1065),
    AppThemeStyle.toxicForest => AppPalette.surfaceCard,
    AppThemeStyle.deepSeaNeon => const Color(0xFF003566),
  };
  Color get darkSurfaceHigh => switch (this) {
    AppThemeStyle.classico => const Color(0xFF5A5389),
    AppThemeStyle.digitalPulse => const Color(0xFF3B1B7D),
    AppThemeStyle.toxicForest => AppPalette.surfaceRaised,
    AppThemeStyle.deepSeaNeon => const Color(0xFF004B80),
  };
  Color get darkOutline => switch (this) {
    AppThemeStyle.classico => const Color(0xFF6F68A6),
    AppThemeStyle.digitalPulse => const Color(0xFF581C87),
    AppThemeStyle.toxicForest => AppPalette.outline,
    AppThemeStyle.deepSeaNeon => const Color(0xFF0A4F8A),
  };
  /// Accento predefinito quando si passa a questa palette.
  Color get defaultAccent => switch (this) {
    AppThemeStyle.classico => const Color(0xFFF0C38E),
    AppThemeStyle.digitalPulse => const Color(0xFFF472B6),
    AppThemeStyle.toxicForest => AppPalette.accent,
    AppThemeStyle.deepSeaNeon => const Color(0xFFFFC300),
  };
  /// Dati vitali: distinto dall'accento, non scelto dall'utente.
  Color get defaultTertiary => switch (this) {
    AppThemeStyle.classico => const Color(0xFFF1AA9B),
    AppThemeStyle.digitalPulse => const Color(0xFFC084FC),
    AppThemeStyle.toxicForest => AppPalette.accentSecondary,
    AppThemeStyle.deepSeaNeon => const Color(0xFF00B4D8),
  };
  /// Tono scurito di [defaultAccent], leggibile come ruolo testuale sul tema
  /// chiaro (dove il colore crudo non supera 4,5:1). Prima di questa storia
  /// solo Toxic Forest ne aveva uno: le altre 3 palette usavano l'accento
  /// crudo anche sul chiaro, illeggibile.
  Color get accentOnLight => switch (this) {
    AppThemeStyle.classico => const Color(0xFF6C5840),
    AppThemeStyle.digitalPulse => const Color(0xFF92446D),
    AppThemeStyle.toxicForest => AppPalette.accentOnLight,
    AppThemeStyle.deepSeaNeon => const Color(0xFF735800),
  };
  /// Idem per [defaultTertiary].
  Color get tertiaryOnLight => switch (this) {
    AppThemeStyle.classico => const Color(0xFF79554E),
    AppThemeStyle.digitalPulse => const Color(0xFF734F97),
    AppThemeStyle.toxicForest => AppPalette.accentSecondaryOnLight,
    AppThemeStyle.deepSeaNeon => const Color(0xFF00758C),
  };
  /// Preset di colore delle azioni per questa palette. Il primo e sempre
  /// [defaultAccent], il secondo [defaultTertiary] (stesso ordine del mockup
  /// per Toxic Forest); gli altri completano la famiglia cromatica. Ognuno
  /// supera 4,5:1 su [darkBackground] e su [darkSurface] — verificato da
  /// `test/contrast_test.dart`.
  List<Color> get accentPresets => switch (this) {
    AppThemeStyle.classico => const <Color>[
      Color(0xFFF0C38E),
      Color(0xFFF1AA9B),
      Color(0xFFE8B4A8),
      Color(0xFFFFB88C),
      Color(0xFFEAD196),
      Color(0xFFF4B9C2),
    ],
    AppThemeStyle.digitalPulse => const <Color>[
      Color(0xFFF472B6),
      Color(0xFFC084FC),
      Color(0xFFDDD6FE),
      Color(0xFF38BDF8),
      Color(0xFF4ADE80),
      Color(0xFFFB7185),
    ],
    AppThemeStyle.toxicForest => AppPalette.accentPresets,
    AppThemeStyle.deepSeaNeon => const <Color>[
      Color(0xFFFFC300),
      Color(0xFF00B4D8),
      Color(0xFFFFD60A),
      Color(0xFF06D6A0),
      Color(0xFFFF8FA3),
      Color(0xFFE0AAFF),
    ],
  };
  Color get lightBackground => switch (this) {
    AppThemeStyle.classico => const Color(0xFFF5F3FA),
    AppThemeStyle.digitalPulse => const Color(0xFFF8F5FF),
    AppThemeStyle.toxicForest => AppPalette.lightBackground,
    AppThemeStyle.deepSeaNeon => const Color(0xFFF0F4F8),
  };
  Color get lightSurface => switch (this) {
    AppThemeStyle.classico => const Color(0xFFFFFFFF),
    AppThemeStyle.digitalPulse => const Color(0xFFFFFFFF),
    AppThemeStyle.toxicForest => AppPalette.lightSurface,
    AppThemeStyle.deepSeaNeon => const Color(0xFFFFFFFF),
  };
  Color get lightSurfaceAlt => switch (this) {
    AppThemeStyle.classico => const Color(0xFFE9E4F2),
    AppThemeStyle.digitalPulse => const Color(0xFFEDE8F8),
    AppThemeStyle.toxicForest => AppPalette.lightSurfaceAlt,
    AppThemeStyle.deepSeaNeon => const Color(0xFFDCE5EE),
  };
}
