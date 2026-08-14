import 'package:flutter/material.dart';

/// Colori di GymFlow.
///
/// Scelti dal prodotto con riferimenti visivi, non derivati algoritmicamente:
/// i rapporti di contrasto di ogni coppia usata dall'interfaccia sono stati
/// misurati e sono verificati da `test/contrast_test.dart`.
///
/// Qui ci sono soltanto i valori. La loro assegnazione ai ruoli Material 3
/// avviene in `app_theme.dart`: chi cerca "di che colore e un bottone" guarda
/// il tema, non questo file.
abstract final class AppPalette {
  // ── Indigo: la famiglia che porta le superfici ──────────────────────────

  /// Sfondo dell'applicazione. Il piu scuro: tutto il resto emerge da qui.
  static const Color indigo900 = Color(0xFF221E3A);

  /// Superficie delle card.
  static const Color indigo800 = Color(0xFF312C51);

  /// Superficie sollevata: card dentro card, elementi flottanti.
  static const Color indigo700 = Color(0xFF48426D);

  /// Bordi e separatori sulle superfici scure.
  static const Color indigo600 = Color(0xFF5A5384);

  /// Elementi di supporto che non sono azioni.
  static const Color indigo400 = Color(0xFF8B84B8);

  // ── Accenti: uno per le azioni, uno per i dati ─────────────────────────

  /// Ambra. **Un solo significato: cosa fare adesso.**
  ///
  /// Se compare su qualcosa che non e un'azione, l'occhio impara a ignorarlo
  /// e il colore perde la sua funzione.
  static const Color amber = Color(0xFFF0C38E);

  /// Ambra spento, per gli stati disabilitati e i contenitori.
  static const Color amberMuted = Color(0xFF8A6E4E);

  /// Salmone. Riservato ai **dati vitali**: battito, sforzo percepito.
  ///
  /// Distinto dall'ambra di proposito: una metrica non e un pulsante.
  static const Color salmon = Color(0xFFF1AA9B);

  /// Salmone spento, per i contenitori.
  static const Color salmonMuted = Color(0xFF8C5F55);

  // ── Neutri ──────────────────────────────────────────────────────────────

  /// Bianco freddo, virato verso l'indigo: un bianco puro sull'indigo
  /// sembrerebbe staccato.
  static const Color paper = Color(0xFFF7F5FB);

  /// Testo secondario sulle superfici scure.
  static const Color paperDim = Color(0xFFB8B2D0);

  // ── Tema chiaro ─────────────────────────────────────────────────────────

  /// Fondo del tema chiaro, con la stessa vira verso l'indigo.
  static const Color lightBackground = Color(0xFFF2F0F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFE9E5F3);

  /// Testo sul tema chiaro.
  static const Color lightOnSurface = Color(0xFF241F3C);
  static const Color lightOnSurfaceDim = Color(0xFF6A648A);

  /// Sul tema chiaro l'ambra non ha contrasto sufficiente per il testo:
  /// serve una variante scurita per i ruoli testuali.
  static const Color amberOnLight = Color(0xFF7A5A2E);

  /// Idem per il salmone.
  static const Color salmonOnLight = Color(0xFF8E4436);

  // ── Semantici: separati dagli accenti ──────────────────────────────────

  static const Color success = Color(0xFF7BC49A);
  static const Color warning = Color(0xFFE8B54A);
  static const Color danger = Color(0xFFE2685C);

  // ── Categorico: identita di serie in un grafico, non un'azione ──────────

  /// Le tinte per distinguere categorie in un grafico — per esempio i tipi
  /// di allenamento in un grafico a torta — dove servono piu tinte
  /// genuinamente separate di quante ne offra il `ColorScheme` (indaco,
  /// ambra, salmone). Ambra e salmone restano riservati al loro significato
  /// e non entrano in questo elenco.
  ///
  /// Valori e **ordine** dalla palette di riferimento del skill "dataviz"
  /// (i primi quattro slot, gia validati per accoppiamenti in entrambe le
  /// direzioni di daltonismo), verificati con
  /// `validate_palette.js "#3987E5,#D95926,#199E70,#C98500" --mode dark
  /// --surface "#221E3A"` sulla superficie di [indigo900]: tutti i controlli
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
  /// Ognuno supera 4,5:1 su [indigo900] e su [indigo800]: la scelta e libera
  /// dentro un insieme che non produce testo illeggibile.
  /// Verificato da `test/contrast_test.dart`.
  static const List<Color> accentPresets = <Color>[
    amber, // ambra, predefinito
    salmon, // salmone
    Color(0xFF9FD8C0), // menta
    Color(0xFFB9AEE8), // lilla
    Color(0xFF8FC7E8), // cielo
    Color(0xFFE8C8DC), // rosa cipria
  ];
}

/// I quattro stili visivi completi dell'applicazione:
/// - [defaultStyle]: GymFlow Classico (Indigo, Ambra, Salmone)
/// - [digitalPulse]: Digital Pulse (#0F172A, #2E1065, #F472B6, #DDD6FE)
/// - [toxicForest]: Toxic Forest (#0B2027, #143540, #EEF800, #AACC00, #80B918)
/// - [deepSeaNeon]: Deep Sea Neon (#000814, #001D3D, #003566, #FFC300, #FFD60A)
enum AppThemeStyle {
  defaultStyle,
  digitalPulse,
  toxicForest,
  deepSeaNeon;

  /// Chiave di localizzazione per il nome
  String get labelKey => switch (this) {
        AppThemeStyle.defaultStyle => 'theme_style_default',
        AppThemeStyle.digitalPulse => 'theme_style_digital_pulse',
        AppThemeStyle.toxicForest => 'theme_style_toxic_forest',
        AppThemeStyle.deepSeaNeon => 'theme_style_deep_sea_neon',
      };

  /// Sfondo principale dark mode
  Color get darkBackground => switch (this) {
        AppThemeStyle.defaultStyle => AppPalette.indigo900,
        AppThemeStyle.digitalPulse => const Color(0xFF0F172A),
        AppThemeStyle.toxicForest => const Color(0xFF0B2027),
        AppThemeStyle.deepSeaNeon => const Color(0xFF000814),
      };

  /// Superficie card dark mode
  Color get darkSurface => switch (this) {
        AppThemeStyle.defaultStyle => AppPalette.indigo800,
        AppThemeStyle.digitalPulse => const Color(0xFF2E1065),
        AppThemeStyle.toxicForest => const Color(0xFF143540),
        AppThemeStyle.deepSeaNeon => const Color(0xFF001D3D),
      };

  /// Superficie sollevata dark mode
  Color get darkSurfaceHigh => switch (this) {
        AppThemeStyle.defaultStyle => AppPalette.indigo700,
        AppThemeStyle.digitalPulse => const Color(0xFF3B1B7D),
        AppThemeStyle.toxicForest => const Color(0xFF1E4B5A),
        AppThemeStyle.deepSeaNeon => const Color(0xFF003566),
      };

  /// Bordi e separatori dark mode
  Color get darkOutline => switch (this) {
        AppThemeStyle.defaultStyle => AppPalette.indigo600,
        AppThemeStyle.digitalPulse => const Color(0xFF581C87),
        AppThemeStyle.toxicForest => const Color(0xFF286274),
        AppThemeStyle.deepSeaNeon => const Color(0xFF0A4F8A),
      };

  /// Accento primario predefinito
  Color get defaultAccent => switch (this) {
        AppThemeStyle.defaultStyle => AppPalette.amber,
        AppThemeStyle.digitalPulse => const Color(0xFFF472B6),
        AppThemeStyle.toxicForest => const Color(0xFFEEF800),
        AppThemeStyle.deepSeaNeon => const Color(0xFFFFC300),
      };

  /// Dati vitali (tertiary)
  Color get defaultTertiary => switch (this) {
        AppThemeStyle.defaultStyle => AppPalette.salmon,
        AppThemeStyle.digitalPulse => const Color(0xFFDDD6FE),
        AppThemeStyle.toxicForest => const Color(0xFF80B918),
        AppThemeStyle.deepSeaNeon => const Color(0xFFFFD60A),
      };

  /// Sottocolori / Colori di accento selezionabili per questo stile
  List<Color> get accentPresets => switch (this) {
        AppThemeStyle.defaultStyle => AppPalette.accentPresets,
        AppThemeStyle.digitalPulse => const <Color>[
            Color(0xFFF472B6), // Magenta neon (#F472B6)
            Color(0xFFDDD6FE), // Lavanda (#DDD6FE)
            Color(0xFFA855F7), // Viola elettrico (#A855F7)
            Color(0xFF38BDF8), // Ciano brillante (#38BDF8)
            Color(0xFF4ADE80), // Menta neon (#4ADE80)
            Color(0xFFFB7185), // Rosa corallo (#FB7185)
          ],
        AppThemeStyle.toxicForest => const <Color>[
            Color(0xFFEEF800), // Giallo neon (#EEF800)
            Color(0xFFAACC00), // Lime (#AACC00)
            Color(0xFF80B918), // Verde bosco (#80B918)
            Color(0xFF00F5D4), // Teal fluor (#00F5D4)
            Color(0xFF57CC99), // Salvia brillante (#57CC99)
            Color(0xFF80FFDB), // Acquamarina (#80FFDB)
          ],
        AppThemeStyle.deepSeaNeon => const <Color>[
            Color(0xFFFFC300), // Oro Cyberpunk (#FFC300)
            Color(0xFFFFD60A), // Giallo neon (#FFD60A)
            Color(0xFF00B4D8), // Blu oceano (#00B4D8)
            Color(0xFF06D6A0), // Smeraldo (#06D6A0)
            Color(0xFFFF5E7E), // Corallo vivo (#FF5E7E)
            Color(0xFFE0AAFF), // Lilla neon (#E0AAFF)
          ],
      };

  /// Sfondo tema chiaro
  Color get lightBackground => switch (this) {
        AppThemeStyle.defaultStyle => AppPalette.lightBackground,
        AppThemeStyle.digitalPulse => const Color(0xFFF8F5FF),
        AppThemeStyle.toxicForest => const Color(0xFFF0F7F7),
        AppThemeStyle.deepSeaNeon => const Color(0xFFF0F4F8),
      };

  /// Superficie tema chiaro
  Color get lightSurface => switch (this) {
        AppThemeStyle.defaultStyle => AppPalette.lightSurface,
        AppThemeStyle.digitalPulse => const Color(0xFFFFFFFF),
        AppThemeStyle.toxicForest => const Color(0xFFFFFFFF),
        AppThemeStyle.deepSeaNeon => const Color(0xFFFFFFFF),
      };

  /// Superficie alternativa tema chiaro
  Color get lightSurfaceAlt => switch (this) {
        AppThemeStyle.defaultStyle => AppPalette.lightSurfaceAlt,
        AppThemeStyle.digitalPulse => const Color(0xFFEDE8F8),
        AppThemeStyle.toxicForest => const Color(0xFFE0ECEF),
        AppThemeStyle.deepSeaNeon => const Color(0xFFDCE5EE),
      };
}
